def diag($severity; $message): {
  message: $message,
  severity: $severity,
  location: {
    path: "deploy.yml",
    range: {
      start: {
        line: 1,
        column: 1
      }
    }
  }
};

(split("\n") | map(gsub("\r$"; "")) | map(select(length > 0))) as $lines
| ($lines | map(select(test("exception|failed|✘|error:"; "i")))) as $errors
| ($lines
    | map(select(
        test("^\\[[^\\]]+\\]")
        and (test("exception|failed|✘|error:"; "i") | not)
      ))
  ) as $warnings
| {
    source: {
      name: "deployer"
    },
    diagnostics: (
      ($warnings | map(diag("WARNING"; .)))
      + ($errors | map(diag("ERROR"; .)))
    )
  }
