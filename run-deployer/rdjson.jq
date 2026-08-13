# Convert PHP Deployer's log output into a reviewdog rdjson diagnostic
# report: one diagnostic per warning, all errors aggregated into a single
# annotation, and (on a clean successful run) a single INFO diagnostic -
# reported by reviewdog as a GitHub notice annotation.
#
# Deployer prefixes every line of per-host output with "[alias] " - including
# routine task progress like "[web1] ✔ Ok" - so matching on that prefix alone
# (as this used to) flags nearly the whole log as warnings and buries the
# actual signal. Classify by content instead: only lines that actually look
# like an error or warning/deprecation notice are captured, whether or not
# they carry a host prefix.
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
        test("warning|deprecated"; "i")
        and (test("exception|failed|✘|error:"; "i") | not)
      ))
  ) as $warnings
| (if ($status == "0" and ($errors | length) == 0) then
    [diag("INFO";
      if ($url | length) > 0 then
        "Deployer completed successfully. Deployed to " + $url
      else
        "Deployer completed successfully."
      end
    )]
  else
    []
  end) as $notices
| {
    source: {
      name: "deployer"
    },
    diagnostics: (
      ($warnings | map(diag("WARNING"; .)))
      + (if ($errors | length) > 0 then
          [diag("ERROR"; $errors | join("\n"))]
        else
          []
        end)
      + $notices
    )
  }
