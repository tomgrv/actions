def rxesc:
  gsub("(?<c>[.^$|()\\[\\]{}*+?\\\\])"; "\\(.c)");

def verparts:
  ltrimstr("v")
  | (capture("^(?<core>[0-9]+(?:\\.[0-9]+)*)")? // {core: "0"}).core
  | split(".")
  | map(tonumber);

def cmpver(a; b):
  (a | verparts) as $a
  | (b | verparts) as $b
  | ([($a | length), ($b | length)] | max) as $n
  | reduce range(0; $n) as $i
      (0; if . != 0 then . else (($a[$i] // 0) - ($b[$i] // 0)) end);

def parse_cond:
  (capture("^\\s*(?<op>>=|<=|==|!=|>|<)?\\s*(?<ver>[^,\\s]+)\\s*$")? // {op: null, ver: "0"})
  | { op: (.op // "=="), ver: .ver };

def cond_holds(cond; installed):
  if cond.op == ">=" then cmpver(installed; cond.ver) >= 0
  elif cond.op == "<=" then cmpver(installed; cond.ver) <= 0
  elif cond.op == ">" then cmpver(installed; cond.ver) > 0
  elif cond.op == "<" then cmpver(installed; cond.ver) < 0
  elif cond.op == "!=" then cmpver(installed; cond.ver) != 0
  else cmpver(installed; cond.ver) == 0
  end;

def clause_conds:
  split(",") | map(gsub("^\\s+|\\s+$"; "")) | map(select(length > 0)) | map(parse_cond);

def clause_holds(installed):
  clause_conds as $conds | ($conds | all(cond_holds(.; installed)));

def clause_upper:
  clause_conds as $conds
  | ($conds | map(select(.op == "<" or .op == "<=")) | map(.ver)) as $uppers
  | if ($uppers | length) > 0 then
      ($uppers | sort_by(verparts) | .[0])
    else
      null
    end;

def find_locs(name; files):
  ("\"" + (name | rxesc) + "\"\\s*:\\s*\"([^\"]*)\"") as $pat
  | [
      files
      | to_entries[]
      | .key as $path
      | (.value | rtrimstr("\n") | split("\n")) as $lines
      | (
          $lines
          | to_entries
          | map({ line: (.key + 1), matches: [.value | match($pat; "")] })
          | map(select((.matches | length) > 0))
          | first
        ) as $loc
      | select($loc != null)
      | { path: $path, line: $loc.line, matches: $loc.matches }
    ];

def recommended_fix(advisories; installed):
  [
    advisories[]
    | (.affectedVersions // "" | split("|") | map(gsub("^\\s+|\\s+$"; "")) | map(select(length > 0))) as $clauses
    | $clauses[]
    | select(clause_holds(installed))
    | clause_upper
  ] as $uppers
  | {
      hasOpenEnded: (
        [
          advisories[]
          | (.affectedVersions // "" | split("|") | map(gsub("^\\s+|\\s+$"; "")) | map(select(length > 0))) as $clauses
          | $clauses[]
          | select(clause_holds(installed) and (clause_upper == null))
        ] | length > 0
      ),
      version: (
        ($uppers | map(select(. != null))) as $known
        | if ($known | length) > 0 then ($known | sort_by(verparts) | .[-1]) else null end
      )
    };

. as $input
# $filesJsonArr: [{ "<path relative to repo root>": "<raw file content>" }]
# for composer.json plus every local path-repository package's composer.json,
# so requirements declared in a path repo (not just the root manifest) are found.
| (($filesJsonArr // [{}])[0] // {}) as $files
| ($locked // {}) as $locked
| (
    ($input.advisories // {})
    | to_entries
    | map(
        .key as $name
        | .value as $advisories
        | ($locked[$name]) as $installed
        | (if $installed then recommended_fix($advisories; $installed) else { hasOpenEnded: false, version: null } end) as $fix
        | (
            if ($advisories | map(.severity) | any(. == "critical" or . == "high")) then "ERROR"
            elif ($advisories | map(.severity) | any(. == "medium")) then "WARNING"
            else "INFO"
            end
          ) as $severity
        | (
            $name + (if $installed then " " + $installed else "" end) + "\n"
            + (
                $advisories
                | map(
                    .title
                    + (if .cve then " (" + .cve + ")" else "" end)
                    + (if .link then "\n" + .link else "" end)
                  )
                | join("\n")
              ) + "\n"
            + "Severity: " + $severity + "\n"
            + (
                if $fix.version then
                  "Recommended fix: upgrade " + $name + " to ^" + $fix.version
                  + (if $fix.hasOpenEnded then " (verify against the open-ended advisory range above; a newer release may still be required)" else "" end)
                elif $fix.hasOpenEnded then
                  "No upper-bound fix version is published yet for this advisory; check the advisory link and consider a manual upgrade or replacement."
                elif $installed then
                  "Could not determine a recommended fix version automatically; check the advisory link(s) above."
                else
                  "Package is not present in composer.lock; could not determine installed version or a recommended fix."
                end
              )
          ) as $message
        | find_locs($name; $files) as $locs
        | (
            if ($locs | length) > 0 then
              $locs
              | map(
                  . as $loc
                  | {
                      path: $loc.path,
                      range: {
                        start: { line: $loc.line, column: ($loc.matches[0].captures[0].offset + 1) },
                        end: { line: $loc.line, column: ($loc.matches[0].captures[0].offset + $loc.matches[0].captures[0].length + 1) }
                      }
                    }
                  | {
                      message: $message,
                      severity: $severity,
                      location: .
                    }
                    + (
                        if $fix.version then
                          { suggestions: [ { range: .range, text: ("^" + $fix.version) } ] }
                        else
                          {}
                        end
                      )
                )
            else
              [
                {
                  message: $message,
                  severity: $severity,
                  location: { path: "composer.json", range: { start: { line: 1, column: 1 } } }
                }
              ]
            end
          )
      )
    | flatten(1)
  ) as $advisoryDiagnostics
| (
    ($input.abandoned // {})
    | to_entries
    | map(
        .key as $name
        | find_locs($name; $files) as $locs
        | (
            if ($locs | length) > 0 then
              $locs
              | map(
                  {
                    message: (
                      $name + " is abandoned"
                      + (if $input.abandoned[$name] then ", use " + $input.abandoned[$name] + " instead" else "" end)
                    ),
                    severity: "WARNING",
                    location: { path: .path, range: { start: { line: .line, column: 1 } } }
                  }
                )
            else
              [
                {
                  message: (
                    $name + " is abandoned"
                    + (if $input.abandoned[$name] then ", use " + $input.abandoned[$name] + " instead" else "" end)
                  ),
                  severity: "WARNING",
                  location: { path: "composer.json", range: { start: { line: 1, column: 1 } } }
                }
              ]
            end
          )
      )
    | flatten(1)
  ) as $abandonedDiagnostics
| ($advisoryDiagnostics + $abandonedDiagnostics) as $allDiagnostics
| (
    def severity_rank:
      if . == "ERROR" then 0
      elif . == "WARNING" then 1
      else 2
      end;
    $allDiagnostics | sort_by(.severity | severity_rank)
  ) as $diagnostics
| ($maxDiagnostics // 40) as $maxDiagnostics
| ($diagnostics | length) as $total
| (if $total > $maxDiagnostics then $maxDiagnostics - 1 else $total end) as $limit
| ($diagnostics[0:$limit]) as $kept
| (
    if $total > $limit then
      $kept + [{
        message: (
          "\($total - $limit) additional finding(s) omitted to stay under GitHub's annotation limits.\n"
          + "Run `composer audit --locked` locally, or check the full job log, to see the rest."
        ),
        severity: "INFO",
        location: { path: "composer.json", range: { start: { line: 1, column: 1 } } }
      }]
    else
      $kept
    end
  ) as $finalDiagnostics
| {
    source: {
      name: "composer-audit"
    },
    diagnostics: $finalDiagnostics
  }
