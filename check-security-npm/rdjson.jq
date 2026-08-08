.vulnerabilities
| to_entries
| map(
    {
      message: (
        .key + " " + (.value.range // "") + "\n"
        + "Severity: " + (.value.severity // "unknown") + "\n"
        + (
          (.value.via // [])
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
          if .value.fixAvailable == true then
            "fix available via npm audit fix"
          elif (.value.fixAvailable | type) == "object" then
            "fix available via npm audit fix --force; will install "
            + .value.fixAvailable.name + "@" + .value.fixAvailable.version
            + (if .value.fixAvailable.isSemVerMajor then " (breaking change)" else "" end)
          else
            "no automatic fix available"
          end
        ) + "\n"
        + "Affected nodes: " + ((.value.nodes // []) | join(", "))
      ),
      severity: (
        if (.value.severity == "critical" or .value.severity == "high") then "ERROR"
        elif .value.severity == "moderate" then "WARNING"
        else "INFO"
        end
      ),
      location: {
        path: "package-lock.json",
        range: {
          start: {
            line: 1,
            column: 1
          }
        }
      }
    }
  )
| {
    source: {
      name: "npm-audit"
    },
    diagnostics: .
  }
