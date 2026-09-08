# @format

# Guards against re-introducing the staleness bug fixed in #96/#98/#99:
# any action.yml step referencing a sibling action defined in *this same
# repo* must resolve it via `uses: $/<name>` (GitHub's self-repository
# syntax, tracks the exact commit currently running) rather than a fixed
# `uses: tomgrv/actions/<name>@<ref>`, which can point at stale code when
# the sibling's own content changes in the same release that calls it.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
}

@test "no action.yml references a sibling in this repo via a pinned tag/branch" {
  matches=$(grep -rnE "^\s*uses: *tomgrv/actions/" "${REPO_ROOT}" --include="action.yml" || true)
  if [ -n "${matches}" ]; then
    echo "Found pinned same-repo references (should use \$/<name> instead):" >&2
    echo "${matches}" >&2
    return 1
  fi
}

@test "release-promote's own steps all use the \$/<name> syntax" {
  run grep -c "uses: \$/" "${REPO_ROOT}/release-promote/action.yml"
  [ "$status" -eq 0 ]
  [ "$output" -ge 3 ]
}
