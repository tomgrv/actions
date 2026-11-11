#!/usr/bin/sh
# Forge compatibility shim. The configure-ci action sources it from the `gh` wrapper it puts
# on PATH off GitHub; it can also be sourced by hand:
#
#   . ./configure-ci/forge.sh
#
# Exports FORGE=github|forgejo (Forgejo/Gitea expose their REST API under
# .../api/v1 in GITHUB_API_URL; GitHub.com and GHES do not).
#
# On GitHub nothing else happens: the real `gh` CLI is used as-is.
# On Forgejo the runner image has no `gh`, so a `gh` function is defined that
# translates the subcommands this repo uses (api, pr, repo, issue, label) into
# Forgejo REST calls with curl + jq, and prints GitHub-shaped JSON so the
# callers' --json/--jq expressions work unchanged.
#
# shortcut: only the gh flags/endpoints used in this repo are translated;
# extend the case statements below when a script needs another one.

case "${GITHUB_API_URL:-}" in
*/api/v1) FORGE=forgejo ;;
*) FORGE=github ;;
esac
# FORGE is the API family (github|forgejo, Gitea shares Forgejo's); FORGE_FLAVOR also tells
# forgejo from gitea once the configure-ci action has probed it, else it equals FORGE.
FORGE_FLAVOR="${FORGE_FLAVOR:-${FORGE}}"
export FORGE FORGE_FLAVOR

[ "${FORGE}" = forgejo ] || return 0

_fg_curl() { # METHOD URL [JSON_BODY]
  curl -fsS -X "$1" \
    -H "Authorization: token ${GH_TOKEN:-${GITHUB_TOKEN:-}}" \
    -H "Content-Type: application/json" -H "Accept: application/json" \
    ${3:+-d "$3"} "$2"
}

# Forgejo PR object -> the subset of `gh pr --json` fields the scripts use.
_FG_PR='{number, title, state, url: .html_url, headRefName: .head.ref,
  baseRefName: .base.ref, headRepositoryOwner: {login: .head.repo.owner.login},
  merged: (.merged_at != null), closingIssuesReferences: []}'

# Parse gh-style flags into _R _JQ _M _STATE _HEAD _LIM _TITLE _BODY _BASE
# _COLOR _DESC _NAME _P1 _P2 _FIELDS (JSON object built from -f/-F).
_fg_parse() {
  _R="${GITHUB_REPOSITORY:-}" _JQ=. _M=GET _STATE=open _HEAD="" _LIM=30
  _TITLE="" _BODY="" _BASE="" _COLOR="" _DESC="" _NAME="" _P1="" _P2=""
  _HAS_TITLE="" _HAS_BODY="" _FIELDS='{}'
  while [ $# -gt 0 ]; do
    case "$1" in
    --repo | -R) _R="$2"; shift ;;
    --jq | -q) _JQ="$2"; shift ;;
    --json | -H | --header) shift ;;
    --method | -X) _M="$2"; shift ;;
    --state | -s) _STATE="$2"; shift ;;
    --head) _HEAD="$2"; shift ;;
    --limit | -L) _LIM="$2"; shift ;;
    --title) _TITLE="$2" _HAS_TITLE=1; shift ;;
    --body) _BODY="$2" _HAS_BODY=1; shift ;;
    --base) _BASE="$2"; shift ;;
    --color) _COLOR="$2"; shift ;;
    --description) _DESC="$2"; shift ;;
    --name) _NAME="$2"; shift ;;
    -f | --raw-field)
      _FIELDS=$(printf '%s' "${_FIELDS}" | jq --arg k "${2%%=*}" --arg v "${2#*=}" '.[$k]=$v')
      shift
      ;;
    -F | --field)
      _FIELDS=$(printf '%s' "${_FIELDS}" | jq --arg k "${2%%=*}" --arg v "${2#*=}" '.[$k]=($v|try fromjson catch $v)')
      shift
      ;;
    -*) ;;
    *) if [ -z "${_P1}" ]; then _P1="$1"; else _P2="$1"; fi ;;
    esac
    shift
  done
}

# Print stdin through the caller's --jq expression (raw output, like gh).
_fg_out() { jq -r "${_JQ}"; }

# Number of the open PR whose head is the current branch (gh's default target).
_fg_current_pr() {
  _b="${GITHUB_HEAD_REF:-$(git branch --show-current 2>/dev/null)}"
  gh pr list --repo "${_R}" --head "${_b}" --jq '.[0].number // empty'
}

_fg_pr() {
  _sub="$1"
  shift
  _fg_parse "$@"
  _api="${GITHUB_API_URL}/repos/${_R}"
  case "${_sub}" in
  list)
    _all='[]' _p=1
    while :; do
      _pg=$(_fg_curl GET "${_api}/pulls?state=${_STATE}&limit=50&page=${_p}") || return 1
      _all=$(printf '%s\n%s' "${_all}" "${_pg}" | jq -s 'add')
      [ "$(printf '%s' "${_pg}" | jq length)" -lt 50 ] && break
      [ "$(printf '%s' "${_all}" | jq length)" -ge "${_LIM}" ] && break
      _p=$((_p + 1))
    done
    printf '%s' "${_all}" | jq --arg h "${_HEAD}" --argjson n "${_LIM}" \
      "map(${_FG_PR}) | map(select(\$h == \"\" or .headRefName == \$h)) | .[:\$n]" | _fg_out
    ;;
  view)
    _n="${_P1:-$(_fg_current_pr)}"
    _fg_curl GET "${_api}/pulls/${_n}" | jq "${_FG_PR}" | _fg_out
    ;;
  edit)
    _b=$(jq -n --arg t "${_TITLE}" --arg b "${_BODY}" --arg base "${_BASE}" \
      '{} | (if $t != "" then .title=$t else . end)
          | (if $b != "" then .body=$b else . end)
          | (if $base != "" then .base=$base else . end)')
    _fg_curl PATCH "${_api}/pulls/${_P1}" "${_b}" >/dev/null
    ;;
  create)
    _b=$(jq -n --arg h "${_HEAD}" --arg base "${_BASE}" --arg t "${_TITLE}" --arg b "${_BODY}" \
      '{head:$h, base:$base, title:$t, body:$b}')
    _fg_curl POST "${_api}/pulls" "${_b}" | jq -r .html_url
    ;;
  comment) _fg_comment "${_P1}" ;;
  *) echo "gh pr ${_sub}: not supported by the Forgejo shim" >&2 && return 1 ;;
  esac
}

_fg_comment() { # ISSUE_OR_PR_NUMBER
  _fg_curl POST "${GITHUB_API_URL}/repos/${_R}/issues/$1/comments" \
    "$(jq -n --arg b "${_BODY}" '{body:$b}')" >/dev/null
}

_fg_label_id() { # NAME -> id
  _fg_curl GET "${GITHUB_API_URL}/repos/${_R}/labels?limit=200" |
    jq -r --arg n "$1" '.[] | select(.name == $n) | .id' | head -n1
}

_fg_label() {
  _sub="$1"
  shift
  _fg_parse "$@"
  _api="${GITHUB_API_URL}/repos/${_R}/labels"
  case "${_sub}" in
  list)
    _fg_curl GET "${_api}?limit=200" |
      jq 'map({name, color: (.color | ltrimstr("#")), description})' | _fg_out
    ;;
  create)
    _fg_curl POST "${_api}" "$(jq -n --arg n "${_P1}" --arg c "#${_COLOR#\#}" --arg d "${_DESC}" \
      '{name:$n, color:$c, description:$d}')" >/dev/null
    ;;
  delete) _fg_curl DELETE "${_api}/$(_fg_label_id "${_P1}")" >/dev/null ;;
  edit)
    _fg_curl PATCH "${_api}/$(_fg_label_id "${_P1}")" "$(jq -n --arg n "${_NAME}" --arg c "${_COLOR}" --arg d "${_DESC}" \
      '{} | (if $n != "" then .name=$n else . end)
          | (if $c != "" then .color=("#" + ($c | ltrimstr("#"))) else . end)
          | .description=$d')" >/dev/null
    ;;
  *) echo "gh label ${_sub}: not supported by the Forgejo shim" >&2 && return 1 ;;
  esac
}

_fg_api() {
  _fg_parse "$@"
  _path="${_P1#/}"
  case "${_path}" in
  http*) _url="${_path}" ;;
  *) _url="${GITHUB_API_URL}/${_path}" ;;
  esac
  # GitHub git-ref endpoints for branches map onto Forgejo's branch endpoints.
  _url=$(printf '%s' "${_url}" | sed -E 's#/git/refs?/heads/#/branches/#')
  case "${_url}" in
  */commits/*/pulls)
    # Forgejo returns a single PR (404 when none); callers expect an array.
    _fg_curl GET "${_url%s}" 2>/dev/null | jq -s . | _fg_out
    return 0
    ;;
  esac
  case "${_M}" in
  GET | DELETE) _fg_curl "${_M}" "${_url}" | _fg_out ;;
  *) _fg_curl "${_M}" "${_url}" "${_FIELDS}" | _fg_out ;;
  esac
}

gh() {
  _c="$1"
  shift
  case "${_c}" in
  api) _fg_api "$@" ;;
  pr) _fg_pr "$@" ;;
  label) _fg_label "$@" ;;
  issue)
    [ "$1" = comment ] || {
      echo "gh issue $1: not supported by the Forgejo shim" >&2
      return 1
    }
    shift
    _fg_parse "$@"
    _fg_comment "${_P1}"
    ;;
  repo)
    shift
    _fg_parse "$@"
    _fg_curl GET "${GITHUB_API_URL}/repos/${_P1:-${_R}}" |
      jq '{nameWithOwner: .full_name, defaultBranchRef: {name: .default_branch}}' | _fg_out
    ;;
  *)
    echo "gh ${_c}: not supported by the Forgejo shim" >&2
    return 1
    ;;
  esac
}
