#!/usr/bin/sh

set -e

MIN_DAYS="${MIN_DAYS:-10}"
MIN_RUNS="${MIN_RUNS:-10}"
WORKFLOWS="${WORKFLOWS:-}"
REPO="${REPO:-${GITHUB_REPOSITORY:-}}"

if [ -z "$REPO" ]; then
  REPO=$(git config --get remote.origin.url | sed -E 's/.*[:\/]([^\/]+\/[^\.]+)(\.git)?$/\1/')
  if [ -z "$REPO" ]; then
    echo "::error:: could not determine repository from GITHUB_REPOSITORY or git remote." >&2
    exit 1
  fi
fi

echo "Cleaning history for repo: ${REPO}" >&2
echo "Keeping at least ${MIN_DAYS} days and ${MIN_RUNS} runs per workflow" >&2

# Calculate cutoff date (runs older than this AND beyond the min-runs window are deleted)
cutoff=$(date -d "-${MIN_DAYS} days" "+%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || \
         date -v-${MIN_DAYS}d "+%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
echo "Cutoff date: ${cutoff}" >&2

# Build list of workflow IDs to process
if [ -n "$WORKFLOWS" ]; then
  # Look up each workflow file name and resolve to numeric ID
  workflow_ids=""
  all_workflows=$(gh api "repos/${REPO}/actions/workflows" --jq '.workflows[] | "\(.id) \(.path)"')
  for wf_file in $(echo "$WORKFLOWS" | tr ',' ' '); do
    wf_id=$(echo "$all_workflows" | awk -v f="$wf_file" '$2 ~ "/"f"$" || $2 == f {print $1}')
    if [ -n "$wf_id" ]; then
      workflow_ids="${workflow_ids} ${wf_id}"
    else
      echo "::warning:: workflow '${wf_file}' not found, skipping." >&2
    fi
  done
else
  workflow_ids=$(gh api "repos/${REPO}/actions/workflows" --jq '.workflows[].id')
fi

if [ -z "$(echo "$workflow_ids" | tr -d ' ')" ]; then
  echo "::warning:: No workflows found." >&2
  exit 0
fi

for workflow_id in $workflow_ids; do
  echo "Processing workflow ID: ${workflow_id}" >&2

  # Fetch up to 500 runs sorted newest-first (default gh ordering)
  runs_json=$(gh run list --workflow="${workflow_id}" --limit=500 --json databaseId,createdAt 2>/dev/null || echo "[]")

  # Delete runs that are BOTH beyond the min-runs window AND older than cutoff
  to_delete=$(echo "$runs_json" | jq -r \
    --arg cutoff "${cutoff}" \
    --argjson min_runs "${MIN_RUNS}" \
    'sort_by(.createdAt) | reverse |
     to_entries |
     map(select(.index >= ($min_runs | tonumber) and .value.createdAt < $cutoff)) |
     .[].value.databaseId')

  count=0
  for run_id in $to_delete; do
    echo "Deleting run ${run_id}..." >&2
    gh run delete "${run_id}" --repo "${REPO}" 2>/dev/null || true
    count=$((count + 1))
  done

  echo "Deleted ${count} runs for workflow ${workflow_id}." >&2
done

echo "Done." >&2
