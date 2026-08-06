. as $input
| (
    ($input.advisories // {})
    | to_entries
    | map(.value | map(
        {
          message: (
            .packageName + " " + (.affectedVersions // "") + "\n"
            + .title + "\n"
            + (if .cve then "CVE: " + .cve + "\n" else "" end)
            + (if .link then .link + "\n" else "" end)
            + "Severity: " + (.severity // "unknown")
          ),
          severity: (
            if (.severity == "critical" or .severity == "high") then "ERROR"
            elif .severity == "medium" then "WARNING"
            else "INFO"
            end
          ),
          location: {
            path: "composer.lock",
            range: {
              start: {
                line: 1,
                column: 1
              }
            }
          }
        }
      ))
    | flatten(1)
  ) as $advisories
| (
    ($input.abandoned // {})
    | to_entries
    | map(
        {
          message: (
            .key + " is abandoned"
            + (if .value then ", use " + .value + " instead" else "" end)
          ),
          severity: "WARNING",
          location: {
            path: "composer.lock",
            range: {
              start: {
                line: 1,
                column: 1
              }
            }
          }
        }
      )
  ) as $abandoned
| {
    source: {
      name: "composer-audit"
    },
    diagnostics: ($advisories + $abandoned)
  }
