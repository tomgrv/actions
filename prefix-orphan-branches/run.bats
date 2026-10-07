# @format

# Tests prefix-orphan-branches/run.sh: wraps `git fix-orphans` and turns its
# stdout into the renamed-branches/count outputs.

setup() {
  SCRIPT="${BATS_TEST_DIRNAME}/run.sh"
  STUB_DIR="$(mktemp -d)"
  PATH="${STUB_DIR}:${PATH}"

  # `git fix-orphans ...` resolves to this executable; it records its args.
  cat > "${STUB_DIR}/git-fix-orphans" <<EOT
#!/usr/bin/sh
echo "\$*" > "${STUB_DIR}/args"
printf '%s' "\$RENAMES"
EOT
  chmod +x "${STUB_DIR}/git-fix-orphans"
}

teardown() {
  rm -rf "${STUB_DIR}"
}

@test "reports renamed branches and count, pushing by default" {
  run env RENAMES=$'a -> orphan/a\nb -> orphan/b\n' sh "$SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "a -> orphan/a"
  echo "$output" | grep -q "count=2"
  grep -q -- "-p -x orphan/" "${STUB_DIR}/args"
}

@test "dry run does not push" {
  run env RENAMES='a -> orphan/a' DRY_RUN=true sh "$SCRIPT"
  [ "$status" -eq 0 ]
  ! grep -q -- "-p" "${STUB_DIR}/args"
}

@test "reports zero when nothing is renamed" {
  run env RENAMES='' sh "$SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "count=0"
}

@test "passes a custom prefix" {
  run env RENAMES='' ORPHAN_PREFIX=stale/ sh "$SCRIPT"
  [ "$status" -eq 0 ]
  grep -q -- "-x stale/" "${STUB_DIR}/args"
}
