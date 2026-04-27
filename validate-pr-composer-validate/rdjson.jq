def diag($severity; $message): {
  message: $message,
  severity: $severity,
  location: {
    path: "composer.json",
    range: {
      start: {
        line: 1,
        column: 1
      }
    }
  }
};

(split("\n") | map(gsub("\r$"; "")) | map(select(length > 0))) as $lines
| ($lines | map(select(startswith("- ")) | ltrimstr("- "))) as $warnings
| ($lines | map(select(test("is not valid")))) as $invalidSummary
| ($lines
    | map(select(
        (startswith("- ") | not)
        and (test("is valid, but with a few warnings|is valid$|is not valid") | not)
      ))
  ) as $otherErrors
| {
    source: {
      name: "composer-validate"
    },
    diagnostics: (
      ($warnings | map(diag("WARNING"; .)))
      + ($invalidSummary | map(diag("ERROR"; .)))
      + ($otherErrors | map(diag("ERROR"; .)))
    )
  }
