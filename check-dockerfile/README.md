# Check Dockerfile Action

A GitHub Action that validates Dockerfiles against 6 production best practices from [Docker DevOps principles](https://www.linkedin.com/posts/yohan-parent_docker-devops-sre-share-7492635770483023872).

## 🎯 What It Checks

### 1️⃣ Pinned Versions (Required)
- ❌ **Fails if:** `FROM node:latest` or similar `latest` tags found
- ✅ **Passes if:** Base image has pinned version (e.g., `FROM node:20.11-alpine`)
- 📝 **Why:** `latest` is unpredictable — your Tuesday build ≠ Thursday build. Pin versions for reproducible builds.

### 2️⃣ .dockerignore Before COPY (Recommended)
- ⚠️ **Warns if:** `.dockerignore` file doesn't exist
- ✅ **Passes if:** `.dockerignore` is present
- 📝 **Why:** Prevents leaking `.git`, `node_modules`, secrets into the image. Saw 380MB of unnecessary `.git` in production.

### 3️⃣ Multi-Stage Build (Recommended)
- ⚠️ **Warns if:** Only one `FROM` statement (single-stage build)
- ✅ **Passes if:** Multiple stages detected
- 📝 **Why:** Separate build stage (with tools, compiler, webpack) from runtime stage. Reduces image from 1GB to 90MB.

### 4️⃣ Non-Root User (Recommended)
- ❌ **Fails if:** Runs as `USER root`
- ⚠️ **Warns if:** No `USER` statement found
- ✅ **Passes if:** Non-root user declared (e.g., `USER app`)
- 📝 **Why:** Best effort/security ratio. If container is compromised, attacker is not root.

### 5️⃣ HEALTHCHECK (Recommended)
- ⚠️ **Warns if:** No `HEALTHCHECK` defined
- ✅ **Passes if:** `HEALTHCHECK` statement present
- 📝 **Why:** Orchestrators can't maintain unhealthy containers. Without it, dead processes remain in production until manual intervention.

### 6️⃣ Hadolint Linting
- Runs [hadolint](https://github.com/hadolint/hadolint) to catch 50+ additional linting issues
- Runs in CI pipeline automatically
- Free, one-line addition to your workflow

## 📦 Usage

### Basic Usage

```yaml
name: Docker Check
on: [push, pull_request]

jobs:
  docker:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Check Dockerfile
        uses: tomgrv/actions/check-dockerfile@main
        with:
          dockerfile-path: ./Dockerfile
```

### Strict Mode (Fail on Warnings)

```yaml
- name: Check Dockerfile
  uses: tomgrv/actions/check-dockerfile@main
  with:
    dockerfile-path: ./Dockerfile
    strict: 'true'  # Treat warnings as errors
```

### Custom Dockerfile Path

```yaml
- name: Check Dockerfile
  uses: tomgrv/actions/check-dockerfile@main
  with:
    dockerfile-path: ./docker/Dockerfile.prod
```

## 📊 Outputs

The action provides the following outputs:

```yaml
issues-found:     # Number of issues found (integer)
checks-passed:    # Comma-separated list of passed checks
checks-failed:    # Comma-separated list of failed checks
```

### Example: Use Outputs in Later Steps

```yaml
- name: Check Dockerfile
  id: docker-check
  uses: tomgrv/actions/check-dockerfile@main

- name: Report Results
  if: always()
  run: |
    echo "Issues found: ${{ steps.docker-check.outputs.issues-found }}"
    echo "Passed: ${{ steps.docker-check.outputs.checks-passed }}"
    echo "Failed: ${{ steps.docker-check.outputs.checks-failed }}"
```

## ✅ Example: Passing Dockerfile

```dockerfile
# Multi-stage build
FROM node:20.11-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci

# Final stage
FROM node:20.11-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./
COPY . .

# Security
USER node

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node healthcheck.js

CMD ["node", "server.js"]
```

## 🚫 Example: Failing Dockerfile

```dockerfile
# ❌ Using latest
FROM node:latest

WORKDIR /app

# ❌ No .dockerignore, leaks secrets/git
COPY . .

# ❌ Runs as root
# No USER statement

# ❌ No HEALTHCHECK

CMD ["node", "server.js"]
```

## 🔧 Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `dockerfile-path` | No | `./Dockerfile` | Path to Dockerfile |
| `strict` | No | `false` | Treat warnings as errors |
| `hadolint-version` | No | `latest` | Version of hadolint to use |

## 📋 Check Details

### Check Behavior by Mode

**Default Mode** (`strict: false`):
- ✅ Pinned versions: **Required**
- ⚠️ .dockerignore, multi-stage, healthcheck: **Warnings only**

**Strict Mode** (`strict: true`):
- ✅ All checks: **Required**

### Exit Codes

- `0`: All required checks passed (warnings allowed in non-strict mode)
- `1`: One or more required checks failed

## 🛠️ What Gets Checked

The action:
1. ✅ Validates Dockerfile exists
2. ✅ Scans for unpinned `latest` tags
3. ✅ Checks for `.dockerignore` presence
4. ✅ Counts `FROM` statements for multi-stage detection
5. ✅ Parses `USER` directives
6. ✅ Checks for `HEALTHCHECK` directive
7. ✅ Runs hadolint for comprehensive linting

## 🧪 Testing Locally

Run the check locally:

```bash
docker-check/check.sh
```

Set strict mode:

```bash
STRICT=true docker-check/check.sh
```

## 📚 Further Reading

- [Hadolint Documentation](https://github.com/hadolint/hadolint)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Container Security](https://docs.docker.com/engine/security/)

## 📝 License

MIT
