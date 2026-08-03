(split("\n") | map(select(length > 0))) as $lines
| {
    source: {
      name: "lock-coherence"
    },
    diagnostics: (
      $lines
      | map(
          split("\t") as $fields
          | {
              message: ($fields[2] | gsub("\\\\n"; "\n")),
              severity: $fields[1],
              location: {
                path: $fields[0],
                range: {
                  start: {
                    line: 1,
                    column: 1
                  }
                }
              }
            }
        )
    )
  }
