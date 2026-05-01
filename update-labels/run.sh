#!/usr/bin/sh

set -eu

REPOSITORY="${REPOSITORY:-${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}}"
LABELS_FILE="${LABELS_FILE:-.github/labels.json}"
LABELS="${LABELS:-25 documentation,10 must,20 should,30 could,80 duplicate,90 wont}"

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "::error::GITHUB_TOKEN is required" >&2
  exit 1
fi

export GH_TOKEN="${GITHUB_TOKEN}"

# Create temp files for tracking operations
TMP_DIR=$(mktemp -d)
trap 'rm -rf "${TMP_DIR}"' EXIT

CREATED_FILE="${TMP_DIR}/created"
UPDATED_FILE="${TMP_DIR}/updated"
DELETED_FILE="${TMP_DIR}/deleted"

: >"${CREATED_FILE}"
: >"${UPDATED_FILE}"
: >"${DELETED_FILE}"

# Function to parse label name from "number name" format
parse_label_name() {
  echo "$1" | sed -E 's/^[0-9]+ +//'
}

# Function to parse number from "number name" format
parse_label_number() {
  echo "$1" | sed -E 's/^([0-9]+) +.*/\1/'
}

# Function to generate color from number (simple hash-based color)
generate_color() {
  local num="${1:-0}"
  # Generate a deterministic color based on the number
  # Use different color ranges for different priority levels
  if [ "${num}" -lt 20 ]; then
    echo "d73a4a" # red for high priority
  elif [ "${num}" -lt 40 ]; then
    echo "0075ca" # blue for medium priority
  elif [ "${num}" -lt 60 ]; then
    echo "a2eeef" # cyan for lower priority
  elif [ "${num}" -lt 80 ]; then
    echo "7057ff" # purple for could
  else
    echo "808080" # gray for duplicate/wont
  fi
}

# Check if labels file exists and is readable
if [ -f "${LABELS_FILE}" ]; then
  echo "::notice::Using labels from file: ${LABELS_FILE}" >&2

  # Parse JSON file (Hyouji format: array of objects with name, color, description)
  # Expected format: [{"name":"label-name","color":"hex","description":"desc"},...]
  if ! command -v jq >/dev/null 2>&1; then
    echo "::error::jq is required to parse JSON labels file" >&2
    exit 1
  fi

  # Extract label definitions from JSON
  LABEL_DEFS=$(jq -r '.[] | "\(.name)|\(.color // "")|\(.description // "")"' "${LABELS_FILE}" 2>/dev/null || {
    echo "::error::Failed to parse labels file ${LABELS_FILE}" >&2
    exit 1
  })
else
  echo "::notice::Using labels from input parameter" >&2

  # Parse comma-separated list
  LABEL_DEFS=""
  IFS=','
  for label_spec in ${LABELS}; do
    label_spec=$(echo "${label_spec}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # Check if it has a number prefix
    if echo "${label_spec}" | grep -qE '^[0-9]+ +'; then
      label_num=$(parse_label_number "${label_spec}")
      label_name=$(parse_label_name "${label_spec}")
      label_color=$(generate_color "${label_num}")
    else
      label_name="${label_spec}"
      label_color=$(generate_color 50)
    fi

    LABEL_DEFS="${LABEL_DEFS}${label_name}|${label_color}|
"
  done
  unset IFS
fi

# Save desired labels to file
echo "${LABEL_DEFS}" >"${TMP_DIR}/desired_labels"

# Get existing labels from repository
echo "::notice::Fetching existing labels from ${REPOSITORY}" >&2
EXISTING_LABELS=$(gh label list --repo "${REPOSITORY}" --limit 1000 --json name,color,description --jq '.[] | "\(.name)|\(.color)|\(.description)"' 2>/dev/null || true)

# Save existing labels to file
echo "${EXISTING_LABELS}" >"${TMP_DIR}/existing_labels"

# Process each desired label
while IFS='|' read -r label_name label_color label_desc; do
  # Skip empty lines
  [ -z "${label_name}" ] && continue

  # Check if label exists
  existing_label=$(grep -F "${label_name}|" "${TMP_DIR}/existing_labels" || true)

  if [ -n "${existing_label}" ]; then
    # Label exists - check if it needs updating
    existing_color=$(echo "${existing_label}" | cut -d'|' -f2)
    existing_desc=$(echo "${existing_label}" | cut -d'|' -f3)

    needs_update=0

    # Normalize colors (remove # if present)
    label_color_norm=$(echo "${label_color}" | sed 's/^#//')
    existing_color_norm=$(echo "${existing_color}" | sed 's/^#//')

    if [ "${label_color_norm}" != "${existing_color_norm}" ] && [ -n "${label_color_norm}" ]; then
      needs_update=1
    fi

    if [ "${label_desc}" != "${existing_desc}" ] && [ -n "${label_desc}" ]; then
      needs_update=1
    fi

    if [ ${needs_update} -eq 1 ]; then
      echo "::notice::Updating label: ${label_name}" >&2

      edit_args="--repo ${REPOSITORY}"
      [ -n "${label_color_norm}" ] && edit_args="${edit_args} --color ${label_color_norm}"
      [ -n "${label_desc}" ] && edit_args="${edit_args} --description ${label_desc}"

      # shellcheck disable=SC2086
      if gh label edit "${label_name}" ${edit_args} >/dev/null 2>&1; then
        echo "1" >>"${UPDATED_FILE}"
      else
        echo "::warning::Failed to update label: ${label_name}" >&2
      fi
    fi
  else
    # Label doesn't exist - create it
    echo "::notice::Creating label: ${label_name}" >&2

    create_args="--repo ${REPOSITORY}"
    [ -n "${label_color}" ] && create_args="${create_args} --color ${label_color}"
    [ -n "${label_desc}" ] && create_args="${create_args} --description ${label_desc}"

    # Use --force to update if exists
    # shellcheck disable=SC2086
    if gh label create "${label_name}" ${create_args} --force >/dev/null 2>&1; then
      echo "1" >>"${CREATED_FILE}"
    else
      echo "::warning::Failed to create label: ${label_name}" >&2
    fi
  fi
done <"${TMP_DIR}/desired_labels"

# Delete labels that are not in the desired list (only if using file)
if [ -f "${LABELS_FILE}" ]; then
  while IFS='|' read -r existing_name existing_color existing_desc; do
    [ -z "${existing_name}" ] && continue

    # Check if this label is in our desired list
    if ! grep -qF "${existing_name}|" "${TMP_DIR}/desired_labels"; then
      echo "::notice::Deleting label: ${existing_name}" >&2
      if gh label delete "${existing_name}" --repo "${REPOSITORY}" --yes >/dev/null 2>&1; then
        echo "1" >>"${DELETED_FILE}"
      else
        echo "::warning::Failed to delete label: ${existing_name}" >&2
      fi
    fi
  done <"${TMP_DIR}/existing_labels"
fi

# Count operations
CREATED=$(wc -l <"${CREATED_FILE}" | tr -d ' ')
UPDATED=$(wc -l <"${UPDATED_FILE}" | tr -d ' ')
DELETED=$(wc -l <"${DELETED_FILE}" | tr -d ' ')

echo "::notice::Labels updated: ${CREATED} created, ${UPDATED} updated, ${DELETED} deleted" >&2

printf 'labels-created=%s\n' "${CREATED}"
printf 'labels-updated=%s\n' "${UPDATED}"
printf 'labels-deleted=%s\n' "${DELETED}"
