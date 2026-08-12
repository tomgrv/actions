# BATS Test Suite for Composite Actions

This directory contains comprehensive BATS (Bash Automated Testing System) tests for all composite actions in the tomgrv/actions repository.

## Structure

```
test/
├── README.md                          # This file
├── run-all-tests.sh                  # Test runner script
├── resolve-environment/
│   └── run.bats                      # Tests for resolve-environment action
├── detect-changes/
│   └── run.bats                      # Tests for detect-changes action
├── config-bot/
│   └── run.bats                      # Tests for config-bot action
├── list-dirty/
│   └── run.bats                      # Tests for list-dirty action
├── list-wip/
│   └── run.bats                      # Tests for list-wip action
├── setup-php/
│   └── run.bats                      # Tests for setup-php action
├── setup-node/
│   └── run.bats                      # Tests for setup-node action
├── check-security-npm/
│   └── run.bats                      # Tests for npm security checks
├── check-security-composer/
│   └── run.bats                      # Tests for composer security checks
├── check-dockerfile/
│   └── run.bats                      # Tests for Dockerfile validation
├── run-phpstan/
│   └── run.bats                      # Tests for PHPStan analysis
├── run-phpinsights/
│   └── run.bats                      # Tests for PHP Insights
├── run-pint/
│   └── run.bats                      # Tests for Laravel Pint
├── run-phpmd/
│   └── run.bats                      # Tests for PHP Mess Detector
├── run-phptests/
│   └── run.bats                      # Tests for PHPUnit
├── run-filacheck/
│   └── run.bats                      # Tests for FilaCheck
├── split-package/
│   └── run.bats                      # Tests for package splitting
├── run-deployer/
│   ├── rdjson.bats                   # Tests for deployer JSON formatting
│   └── fixtures/                     # Test fixtures for run-deployer
└── [additional test directories]/
```

## Test Coverage

### Utility Actions
- **resolve-environment** - Resolves deploy branch, tag, and environment from GitHub events
- **detect-changes** - Detects uncommitted or untracked changes
- **config-bot** - Configures git bot identity
- **setup-php** - Sets up PHP and Composer
- **setup-node** - Sets up Node.js and npm

### File Management Actions
- **list-dirty** - Lists files with uncommitted changes
- **list-wip** - Lists files changed on current branch
- **split-package** - Splits monorepo package to separate repository

### Security Checks
- **check-security-npm** - Audits npm dependencies
- **check-security-composer** - Audits Composer dependencies
- **check-dockerfile** - Validates Dockerfile syntax

### PHP Analysis
- **run-phpstan** - PHPStan static analysis
- **run-phpinsights** - PHP Insights code quality
- **run-pint** - Laravel Pint code style checks
- **run-phpmd** - PHP Mess Detector analysis
- **run-phptests** - PHPUnit test execution
- **run-filacheck** - FilaCheck Filament analysis

### Other Actions
- **run-deployer** - PHP Deployer execution and reporting

## Running Tests

### Run All Tests

```bash
./test/run-all-tests.sh
```

### Run Specific Action Tests

```bash
./test/run-all-tests.sh -f resolve-environment
./test/run-all-tests.sh -f detect-changes
./test/run-all-tests.sh -f list-dirty
```

### Run Tests with Verbose Output

```bash
./test/run-all-tests.sh -v
```

### Run Tests Quietly

```bash
./test/run-all-tests.sh -q
```

### Run Individual Test Files

```bash
bats test/resolve-environment/run.bats
bats test/detect-changes/run.bats
bats test/config-bot/run.bats
```

## Test Patterns and Conventions

### Setup/Teardown

Each test file follows BATS conventions:

```bash
setup() {
  # Initialize test environment
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  SCRIPT="${REPO_ROOT}/action-name/run.sh"
  # Create temporary directories for file-based tests
  TEST_DIR="$(mktemp -d)"
  cd "$TEST_DIR"
}

teardown() {
  # Clean up temporary directories
  rm -rf "$TEST_DIR"
}
```

### Helper Functions

Each test file defines helper functions to run scripts with controlled inputs:

```bash
run_action() {
  (
    export VAR1="$1"
    export VAR2="$2"
    sh "$SCRIPT" 2>/dev/null
  )
}
```

### Output Validation

Tests validate output format and content:

```bash
@test "outputs key=value format" {
  run run_action "input"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^key=value$"
}
```

### Fixture Management

Complex tests use fixture files for test data:

```bash
setup() {
  FIXTURES="${BATS_TEST_DIRNAME}/fixtures"
}

@test "test with fixture" {
  run run_action "$(cat "${FIXTURES}/test-data.txt")"
  [ "$status" -eq 0 ]
}
```

## Writing New Tests

### Test File Template

```bash
# @format

# Tests action-name/run.sh: Brief description of what the action does.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  SCRIPT="${REPO_ROOT}/action-name/run.sh"
}

run_action() {
  (
    export INPUT1="${1:-.}"
    export INPUT2="${2:-default}"
    sh "$SCRIPT" 2>/dev/null
  )
}

@test "test case 1: description" {
  run run_action "input" "value"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "expected_pattern"
}

@test "test case 2: description" {
  run run_action "different" "input"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "other_pattern"
}
```

### Test Case Guidelines

1. **One assertion per concept** - Each test should validate a single behavior
2. **Descriptive names** - Use clear, specific test names
3. **Isolation** - Each test should be independent
4. **Setup/Teardown** - Use setup/teardown for initialization and cleanup
5. **Error conditions** - Test both success and failure paths
6. **Environment variables** - Test with various environment configurations
7. **Output validation** - Verify both exit status and output format

## CI Integration

Tests are designed to run in CI environments without external dependencies:

```yaml
# Example GitHub Actions workflow
- name: Run tests
  run: ./test/run-all-tests.sh

- name: Run specific action tests
  run: ./test/run-all-tests.sh -f detect-changes
```

## Dependencies

- **bats** - Bash Automated Testing System
  ```bash
  npm install -g bats
  ```

- **git** - For git-based tests
- **jq** - For JSON parsing (required by some tests)
- **composer** - For PHP action tests (optional)
- **php** - For PHP action tests (optional)
- **node** - For Node.js action tests (optional)

## Installation

```bash
# Install BATS
npm install -g bats

# Or use your system package manager
brew install bats-core        # macOS
apt-get install bats          # Ubuntu/Debian
```

## Best Practices

### Environment Isolation

Use subshells and temporary directories to isolate tests:

```bash
@test "test with isolated environment" {
  TEST_DIR="$(mktemp -d)"
  (
    cd "$TEST_DIR"
    run run_action
    [ "$status" -eq 0 ]
  )
  rm -rf "$TEST_DIR"
}
```

### Error Handling

Test error conditions and expected failures:

```bash
@test "error condition" {
  run run_action "invalid_input"
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "Error:"
}
```

### Git Operations

For tests involving git operations:

```bash
@test "git operation" {
  TEST_DIR="$(mktemp -d)"
  cd "$TEST_DIR"
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"
  # ... rest of test
  rm -rf "$TEST_DIR"
}
```

## Troubleshooting

### BATS Not Found

```bash
# Install BATS
npm install -g bats
# Or
brew install bats-core
```

### Permission Denied

```bash
chmod +x ./test/run-all-tests.sh
```

### Tests Fail Unexpectedly

1. Run with verbose output: `./test/run-all-tests.sh -v`
2. Check temporary directory cleanup
3. Verify environment variables
4. Review git configuration

## Contributing

When adding new actions or modifying existing ones:

1. Add corresponding test file in `test/<action-name>/run.bats`
2. Include setup/teardown for environment management
3. Write tests covering success and failure paths
4. Test all input parameters and defaults
5. Run full test suite: `./test/run-all-tests.sh`
6. Include new test file in version control

## Resources

- [BATS Documentation](https://github.com/bats-core/bats-core)
- [BATS Tutorial](https://github.com/bats-core/bats-core/wiki/Background)
- [Bash Testing Best Practices](https://bats-core.readthedocs.io/)
