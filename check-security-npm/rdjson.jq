# Convert `npm audit --json` output into a reviewdog rdjson diagnostic
# report, resolving each advisory to the manifest line that declares the
# affected package.
def rxesc:
  gsub("(?<c>[.^$|()\\[\\]{}*+?\\\\])"; "\\(.c)");

def severity_rank:
  if . == "critical" then 0
  elif . == "high" then 1
  elif . == "moderate" then 2
  elif . == "low" then 3
  else 4
  end;

# $filesJsonArr: [{ "<path relative to repo root>": "<raw file content>" }]
# for package.json plus every npm workspace member's package.json, so direct
# dependencies declared in a workspace (not just the root manifest) are found.
(($filesJsonArr // [{}])[0] // {}) as $files
| def find_locs(name):
    ("\"" + (name | rxesc) + "\"\\s*:\\s*\"([^\"]*)\"") as $pat
    | [
        $files
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

($maxDiagnostics // 40) as $maxDiagnostics
| (.vulnerabilities // {})
| to_entries
| map(
    .key as $name
    | .value as $v
    | (
        if $v.fixAvailable == true then null
        elif ($v.fixAvailable | type) == "object" then $v.fixAvailable.version
        else null
        end
      ) as $fixVersion
    | (if $v.isDirect == true then find_locs($name) else [] end) as $locs
    | (
        $v.severity | severity_rank
      ) as $rank
    | (
        $name + " " + ($v.range // "") + "\n"
        + "Severity: " + ($v.severity // "unknown") + "\n"
        + (
            ($v.via // [])
            | map(
                if type == "object" then
                  .title + (if .url then "\n" + .url else "" end)
                else
                  "via: " + .
                end
              )
            | join("\n")
          ) + "\n"
        + (
            if $fixVersion then
              "Recommended fix: upgrade to " + $name + "@" + $fixVersion
              + (if ($v.fixAvailable | type) == "object" and $v.fixAvailable.isSemVerMajor then " (breaking change)" else "" end)
            elif $v.fixAvailable == true then
              "Run `npm audit fix` to resolve automatically."
            else
              "No automatic fix available."
            end
          ) + "\n"
        + (if $v.isDirect != true then "Transitive dependency: update the package(s) that depend on it.\n" else "" end)
        + "Affected nodes: " + (($v.nodes // []) | join(", "))
      ) as $message
    | (
        if ($v.severity == "critical" or $v.severity == "high") then "ERROR"
        elif $v.severity == "moderate" then "WARNING"
        else "INFO"
        end
      ) as $severity
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
                  rank: $rank,
                  diagnostic: (
                    {
                      message: $message,
                      severity: $severity,
                      location: .
                    }
                    + (
                        if $fixVersion then
                          { suggestions: [ { range: .range, text: $fixVersion } ] }
                        else
                          {}
                        end
                      )
                  )
                }
            )
        else
          [
            {
              rank: $rank,
              diagnostic: {
                message: $message,
                severity: $severity,
                location: { path: "package.json", range: { start: { line: 1, column: 1 } } }
              }
            }
          ]
        end
      )
  )
| flatten(1)
| sort_by(.rank)
| map(.diagnostic)
| (length) as $total
| (if $total > $maxDiagnostics then $maxDiagnostics - 1 else $total end) as $limit
| .[0:$limit] as $kept
| (
    if $total > $limit then
      $kept + [{
        message: (
          "\($total - $limit) additional vulnerable package(s) omitted to stay under GitHub's annotation limits.\n"
          + "Run `npm audit --workspaces --audit-level moderate` locally, or check the full job log, to see the rest."
        ),
        severity: "INFO",
        location: { path: "package.json", range: { start: { line: 1, column: 1 } } }
      }]
    else
      $kept
    end
  ) as $diagnostics
| {
    source: {
      name: "npm-audit"
    },
    diagnostics: $diagnostics
  }
