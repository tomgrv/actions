def rxesc:
  gsub("(?<c>[.^$|()\\[\\]{}*+?\\\\])"; "\\(.c)");

($pkgjson | rtrimstr("\n") | split("\n")) as $lines
| def find_loc(name):
    ("\"" + (name | rxesc) + "\"\\s*:\\s*\"([^\"]*)\"") as $pat
    | (
        $lines
        | to_entries
        | map({ line: (.key + 1), matches: [.value | match($pat; "")] })
        | map(select((.matches | length) > 0))
        | first
      );
.vulnerabilities
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
    | (if $v.isDirect == true then find_loc($name) else null end) as $loc
    | (
        if $loc then
          {
            path: "package.json",
            range: {
              start: { line: $loc.line, column: ($loc.matches[0].captures[0].offset + 1) },
              end: { line: $loc.line, column: ($loc.matches[0].captures[0].offset + $loc.matches[0].captures[0].length + 1) }
            }
          }
        else
          {
            path: "package.json",
            range: { start: { line: 1, column: 1 } }
          }
        end
      ) as $location
    | {
        message: (
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
        ),
        severity: (
          if ($v.severity == "critical" or $v.severity == "high") then "ERROR"
          elif $v.severity == "moderate" then "WARNING"
          else "INFO"
          end
        ),
        location: $location
      }
      + (
          if $loc and $fixVersion then
            { suggestions: [ { range: $location.range, text: $fixVersion } ] }
          else
            {}
          end
        )
  )
| {
    source: {
      name: "npm-audit"
    },
    diagnostics: .
  }
