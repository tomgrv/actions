if [ -z "${CI_REPO_NAME:-}" ] || [ -z "${CI_REPO_OWNER:-}" ]; then
  export CI_REPO="${GITHUB_REPOSITORY:-$(git config --get remote.origin.url | sed -E 's#.*[:/]([^/]+/[^/.]+)(\.git)?$#\1#')}"
  export CI_REPO_NAME="$(basename "${CI_REPO}")"
  export CI_REPO_OWNER="$(dirname "${CI_REPO}")"
fi

if [ -z "${CI_COMMIT:-}" ]; then
  export CI_COMMIT="$(git rev-parse HEAD)"
fi

if [ -z "${REVIEWDOG_GITHUB_API_TOKEN:-}" ]; then
  export REVIEWDOG_GITHUB_API_TOKEN="${GITHUB_TOKEN}"
fi

if [ -z "${REVIEWDOG_REPORTER:-}" ]; then
  export REVIEWDOG_REPORTER="local"
fi

if [ -z "${CI_PULL_REQUEST:-}" ]; then
  zz_ask "No pull request context detected. Do you want to continue running the tests? (y/N)" && exit 1
fi

$CMD=${1}
$APP=${2:-app,config,database,resources,routes,tests,modules,packages}

if [ -x "$CMD/run.sh" ]; then
  zz_log s "Running $CMD/run.sh $APP"
  sh -c "$CMD/run.sh $APP"
elif [ -f "$CMD" -a -x "$CMD" ]; then
  zz_log s "Running $CMD $APP"
  sh -c "$CMD $APP"
else
  zz_log e "No executable script found at $CMD/run.sh or $CMD"
  exit 1
fi