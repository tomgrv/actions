#!/usr/bin/sh

set -eu

REPOSITORY="${REPOSITORY:-${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}}"
LABELS_FILE="${LABELS_FILE:-.github/labels.json}"
LABELS="${LABELS:-50 documentation,10 must,20 should,30 could,80 duplicate,90 wont}"

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "::error::GITHUB_TOKEN is required" >&2
  exit 1
fi

export GH_TOKEN="${GITHUB_TOKEN}"

# Function to parse label name from "number name" format to return just the name
parse_label_name() {
  echo "$@" | sed -E 's/^[0-9]+ +//'
}

# Function to parse number from "number name" format
parse_label_number() {
  echo "$@" | sed -E 's/^([0-9]+) +.*/\1/'
}

# Function to generate color from number (simple hash-based color)
generate_color() {
  local num="${1:-0}"
  # Generate a deterministic color based on the number
  # Use different color ranges for different priority levels
  if [ "${num}" -lt 20 ]; then
    echo "b60205" # red for max priority
  elif [ "${num}" -lt 30 ]; then
    echo "fbca04" # yellow for high priority
  elif [ "${num}" -lt 50 ]; then
    echo "0e8a16" # green for medium priority
  elif [ "${num}" -lt 60 ]; then
    echo "006b75" # dark green for low priority
  elif [ "${num}" -lt 80 ]; then
    echo "7057ff" # purple for could
  elif [ "${num}" -lt 90 ]; then
    echo "cfd3d7" # light gray for duplicate
  else
    echo "808080" # dark gray for remaining wontfix or similar
  fi
}

# Get temporary directory for intermediate files
TMP_DIR=$(mktemp -d)

# Check if labels file exists and is readable
if [ -f "${LABELS_FILE}" ]; then
  echo "Using labels from file: ${LABELS_FILE}" >&2

  # Parse JSON file (array of objects with name, color, description)
  # Expected format: [{"name":"label-name","color":"hex","description":"desc"},...]
  if ! command -v jq >/dev/null 2>&1; then
    echo "::error::jq is required to parse JSON labels file" >&2
    exit 1
  fi

  # Extract label definitions from JSON to @sh format: name color description
  jq -r '.[] | [.name, .color, .description] | @tsv' "${LABELS_FILE}" 2>/dev/null
else
  echo "Using comma-separated labels from input: ${LABELS}" >&2

  
  echo "${LABELS}" | tr ',' '\n' | while read -r line; do
    echo "${line}\t$(generate_color $(parse_label_number ${line}))\t${line}"
  done    

fi > "${TMP_DIR}/desired_labels"

# Get existing labels from repository
echo "Fetching existing labels from ${REPOSITORY}" >&2
gh label list --repo "${REPOSITORY}" --limit 1000 --json name,color,description --jq '.[] | [.name, .color, .description] | @tsv' 2>/dev/null > "${TMP_DIR}/existing_labels"


# Label deletion: Remove labels that exist in the repository but are not in the desired list
cat ${TMP_DIR}/existing_labels | tr '\t' '|' | while IFS='|' read -r fullname color desc; do

  name=$(parse_label_name ${fullname})
  
  # Check if label exists in desired list (case-insensitive)
  if ! grep -iqE "^([0-9]+ +)?${name}([[:space:]]|$)" "${TMP_DIR}/desired_labels"; then

    # Attempt to delete label
    if ! gh label delete "${fullname}" --repo "${REPOSITORY}" --yes >&2; then
      echo "::warning::Failed to delete label: ${fullname}" >&2
    fi
  fi
done

# Label creation and update: Create new labels or update existing ones to match desired definitions
cat ${TMP_DIR}/desired_labels  | tr '\t' '|' | while IFS='|' read -r fullname color desc; do

  name=$(parse_label_name "${fullname}")
  
  # Check if label exists in existing list (case-insensitive)
  if ! grep -iqE "^[0-9 ]*${name}" "${TMP_DIR}/existing_labels"; then

     # Attempt to create label
    if ! gh label create "${fullname}" --repo "${REPOSITORY}" --color "${color}" --description "${desc}" >&2; then
      echo "::warning::Failed to create label: ${fullname}" >&2
    fi

  # If label exists but color or description differ, attempt to update (case-insensitive name match)
  elif ! grep -iqE "^[0-9]* ${name}[[:space:]]+${color}[[:space:]]+${desc}$" "${TMP_DIR}/existing_labels"; then

    # Get the actual existing label name (in case of case differences or formatting or number prefix)
    oldname=$(grep -iE "^[0-9 ]*${name}" "${TMP_DIR}/existing_labels" | head -n 1 | cut -f1)

    # Attempt to update label (color and description)
    if ! gh label edit "${oldname}" --repo "${REPOSITORY}" --color "${color}" --description "${desc}" --name "${fullname}" >&2; then
      echo "::warning::Failed to update label: ${fullname}" >&2
    fi
  fi
done

# Clean up temporary files
rm -rf "${TMP_DIR}"


