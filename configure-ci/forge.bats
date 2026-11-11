# @format

# Tests forge.sh: GitHub is left untouched, Forgejo gets a `gh` shim over curl.

setup() {
  LIB="${BATS_TEST_DIRNAME}/forge.sh"
  STUB_DIR="$(mktemp -d)"
  PATH="${STUB_DIR}:${PATH}"
  # curl stub: log "METHOD URL BODY", answer with a canned Forgejo PR.
  cat >"${STUB_DIR}/curl" <<'EOF'
#!/bin/sh
m=GET; body=""; url=""
while [ $# -gt 0 ]; do case "$1" in -X) m=$2; shift;; -d) body=$2; shift;; -H) shift;; -*) ;; *) url=$1;; esac; shift; done
echo "$m $url $body" >>"${STUB_DIR}/calls.log"
case "$url" in
*"/pulls?"*"page=1") echo '[{"number":7,"title":"t","state":"open","html_url":"u","merged_at":null,"head":{"ref":"feat","repo":{"owner":{"login":"o"}}},"base":{"ref":"main"}}]' ;;
*"/pulls?"*) echo '[]' ;;
*"/repos/o/r") echo '{"full_name":"o/r","default_branch":"develop"}' ;;
*) echo '{}' ;;
esac
EOF
  chmod +x "${STUB_DIR}/curl"
  export STUB_DIR GITHUB_TOKEN=tok GITHUB_REPOSITORY=o/r
}

teardown() { rm -rf "${STUB_DIR}"; }

@test "github: FORGE=github and no gh function is defined" {
  run env GITHUB_API_URL=https://api.github.com sh -c ". '${LIB}'; echo \$FORGE; command -v gh || true"
  [ "${lines[0]}" = github ]
  # a function would be printed as the bare word `gh`, a binary as its path
  [ "${lines[1]:-}" != gh ]
}

@test "forgejo: pr list returns gh-shaped fields filtered by head" {
  run env GITHUB_API_URL=http://f/api/v1 sh -c ". '${LIB}'; gh pr list --repo o/r --state open --head feat --json number --jq '.[0].headRepositoryOwner.login'"
  [ "$status" -eq 0 ]
  [ "$output" = o ]
}

@test "forgejo: repo view maps default_branch" {
  run env GITHUB_API_URL=http://f/api/v1 sh -c ". '${LIB}'; gh repo view o/r --json defaultBranchRef --jq .defaultBranchRef.name"
  [ "$output" = develop ]
}

@test "forgejo: pr create/edit/comment hit the pulls and issues endpoints" {
  run env GITHUB_API_URL=http://f/api/v1 sh -c ". '${LIB}'; gh pr create --repo o/r --head o:feat --base main --title T --body B; gh pr edit 7 --repo o/r --title N; gh pr comment 7 --repo o/r --body hi"
  [ "$status" -eq 0 ]
  grep -q '^POST http://f/api/v1/repos/o/r/pulls ' "${STUB_DIR}/calls.log"
  grep -q '^PATCH http://f/api/v1/repos/o/r/pulls/7 .*"title": "N"' <(tr -d '\n' <"${STUB_DIR}/calls.log" | sed 's/PATCH/\nPATCH/g')
  grep -q '^POST http://f/api/v1/repos/o/r/issues/7/comments ' "${STUB_DIR}/calls.log"
}

@test "forgejo: gh api maps GitHub git/refs/heads to branches" {
  run env GITHUB_API_URL=http://f/api/v1 sh -c ". '${LIB}'; gh api -X DELETE repos/o/r/git/refs/heads/x"
  [ "$status" -eq 0 ]
  grep -q '^DELETE http://f/api/v1/repos/o/r/branches/x' "${STUB_DIR}/calls.log"
}

@test "forgejo: unsupported subcommand fails loudly" {
  run env GITHUB_API_URL=http://f/api/v1 sh -c ". '${LIB}'; gh release list"
  [ "$status" -ne 0 ]
  [[ "$output" == *"not supported by the Forgejo shim"* ]]
}
