#!/bin/bash
set -o pipefail

DOCKERFILE="${DOCKERFILE:=./Dockerfile}"
STRICT="${STRICT:=false}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

passed_checks=()
failed_checks=()
issues_count=0

echo "🐳 Checking Dockerfile: $DOCKERFILE"
echo "=================================="

# Check if Dockerfile exists
if [ ! -f "$DOCKERFILE" ]; then
  echo -e "${RED}✗ Dockerfile not found at $DOCKERFILE${NC}"
  echo "issues-found=1" >> "$GITHUB_OUTPUT"
  echo "checks-passed=" >> "$GITHUB_OUTPUT"
  echo "checks-failed=file-exists" >> "$GITHUB_OUTPUT"
  exit 1
fi

# 1. Check for pinned versions (no 'latest' tag)
check_pinned_versions() {
  echo -n "1️⃣  Pinned versions (no 'latest' tag)... "
  if grep -q "FROM.*:latest" "$DOCKERFILE"; then
    echo -e "${RED}✗ FAILED${NC}"
    echo "   Found 'latest' tag in FROM clause. Use pinned versions for reproducible builds."
    failed_checks+=("pinned-versions")
    ((issues_count++))
    return 1
  else
    echo -e "${GREEN}✓ PASSED${NC}"
    passed_checks+=("pinned-versions")
    return 0
  fi
}

# 2. Check for .dockerignore before COPY
check_dockerignore() {
  echo -n "2️⃣  .dockerignore before COPY... "
  if [ ! -f ".dockerignore" ]; then
    echo -e "${YELLOW}⚠ WARNING${NC}"
    echo "   .dockerignore not found. Prevents leaking .git, node_modules, secrets."
    if [ "$STRICT" = "true" ]; then
      failed_checks+=("dockerignore")
      ((issues_count++))
      return 1
    else
      passed_checks+=("dockerignore")
      return 0
    fi
  else
    echo -e "${GREEN}✓ PASSED${NC}"
    passed_checks+=("dockerignore")
    return 0
  fi
}

# 3. Check for multi-stage builds
check_multistage() {
  echo -n "3️⃣  Multi-stage build... "
  from_count=$(grep -c "^FROM" "$DOCKERFILE" || true)
  if [ "$from_count" -lt 2 ]; then
    echo -e "${YELLOW}⚠ WARNING${NC}"
    echo "   No multi-stage build detected. Consider separating build and runtime stages."
    if [ "$STRICT" = "true" ]; then
      failed_checks+=("multistage")
      ((issues_count++))
      return 1
    else
      passed_checks+=("multistage")
      return 0
    fi
  else
    echo -e "${GREEN}✓ PASSED${NC} ($(echo $from_count) stages)"
    passed_checks+=("multistage")
    return 0
  fi
}

# 4. Check for non-root user
check_nonroot_user() {
  echo -n "4️⃣  Non-root user... "
  if grep -q "^USER [^r]" "$DOCKERFILE" || grep -q "^USER app" "$DOCKERFILE"; then
    echo -e "${GREEN}✓ PASSED${NC}"
    passed_checks+=("nonroot-user")
    return 0
  elif grep -q "^USER root" "$DOCKERFILE"; then
    echo -e "${RED}✗ FAILED${NC}"
    echo "   Container runs as root. Add 'USER app' for security."
    failed_checks+=("nonroot-user")
    ((issues_count++))
    return 1
  else
    echo -e "${YELLOW}⚠ WARNING${NC}"
    echo "   No USER statement found. Consider running as non-root for security."
    if [ "$STRICT" = "true" ]; then
      failed_checks+=("nonroot-user")
      ((issues_count++))
      return 1
    else
      passed_checks+=("nonroot-user")
      return 0
    fi
  fi
}

# 5. Check for HEALTHCHECK
check_healthcheck() {
  echo -n "5️⃣  HEALTHCHECK... "
  if grep -q "^HEALTHCHECK" "$DOCKERFILE"; then
    echo -e "${GREEN}✓ PASSED${NC}"
    passed_checks+=("healthcheck")
    return 0
  else
    echo -e "${YELLOW}⚠ WARNING${NC}"
    echo "   No HEALTHCHECK defined. Orchestrators need it to detect stuck processes."
    if [ "$STRICT" = "true" ]; then
      failed_checks+=("healthcheck")
      ((issues_count++))
      return 1
    else
      passed_checks+=("healthcheck")
      return 0
    fi
  fi
}

# Run all checks
check_pinned_versions
check_dockerignore
check_multistage
check_nonroot_user
check_healthcheck

# Output results
echo ""
echo "=================================="
if [ ${#failed_checks[@]} -eq 0 ]; then
  echo -e "${GREEN}✅ All checks passed!${NC}"
  exit_code=0
else
  echo -e "${RED}❌ $((${#failed_checks[@]})) check(s) failed${NC}"
  exit_code=1
fi

# Set GitHub Actions outputs
passed_csv=$(IFS=,; echo "${passed_checks[*]}")
failed_csv=$(IFS=,; echo "${failed_checks[*]}")

{
  echo "issues-found=$issues_count"
  echo "checks-passed=$passed_csv"
  echo "checks-failed=$failed_csv"
} >> "$GITHUB_OUTPUT"

exit $exit_code
