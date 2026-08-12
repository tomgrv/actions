# Check Dockerfile Action

A GitHub Action that validates Dockerfiles against 6 production best practices from [Docker DevOps principles](https://www.linkedin.com/posts/yohan-parent_docker-devops-sre-share-7492635770483023872).

Reports findings via [reviewdog](https://github.com/reviewdog/reviewdog) with inline GitHub annotations.

## 🎯 What It Checks

### 1️⃣ Pinned Versions (Required)
- ❌ **Fails if:** `FROM node:latest` or similar `latest` tags found
- ✅ **Passes if:** Base image has pinned version (e.g., `FROM node:20.11-alpine`)
- **Why:** `latest` is unpredictable. Pin versions for reproducible builds.

### 2️⃣ .dockerignore (Warning / Strict)
- ⚠️ **Warns if:** `.dockerignore` file doesn't exist
- **Why:** Prevents leaking `.git`, `node_modules`, secrets. Prevents 380MB+ of unnecessary data in images.

### 3️⃣ Multi-Stage Build (Warning / Strict)
- ⚠️ **Warns if:** Only one `FROM` statement (single-stage build)
- **Why:** Separate build stage from runtime. Reduces image size from 1GB to 90MB.

### 4️⃣ Non-Root User (Warning / Strict)
- ⚠️ **Warns if:** No `USER` statement or runs as `root`
- **Why:** Best effort/security ratio. Non-root limits blast radius if container is compromised.

### 5️⃣ HEALTHCHECK (Warning / Strict)
- ⚠️ **Warns if:** No `HEALTHCHECK` defined
- **Why:** Orchestrators need it to detect stuck processes. Dead containers stay in production without it.

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
      
      - name: Check Dockerfile best practices
        uses: tomgrv/actions/check-dockerfile@main
        with:
          dockerfile-path: ./Dockerfile
      
      - name: Run hadolint linter
        uses: hadolint/hadolint-action@v3.1.0
        with:
          dockerfile: ./Dockerfile
```

### Strict Mode (Fail on Warnings)

```yaml
- name: Check Dockerfile
  uses: tomgrv/actions/check-dockerfile@main
  with:
    dockerfile-path: ./Dockerfile
    strict: 'true'
```

### Custom Dockerfile Path

```yaml
- name: Check Dockerfile
  uses: tomgrv/actions/check-dockerfile@main
  with:
    dockerfile-path: ./docker/Dockerfile.prod
```

### Pairing with hadolint-action

This action validates 6 specific best practices. Complement it with [hadolint-action](https://github.com/hadolint/hadolint-action) for comprehensive Dockerfile linting (50+ rules):

```yaml
- uses: tomgrv/actions/check-dockerfile@main
  with:
    dockerfile-path: ./Dockerfile
- uses: hadolint/hadolint-action@v3.1.0
  with:
    dockerfile: ./Dockerfile
```

## 📊 Outputs

```yaml
issues-found:     # Total issues (errors + warnings)
checks-failed:    # Number of failed required checks
checks-warned:    # Number of warnings
```

## ✅ Example: Passing Dockerfile

```dockerfile
# Multi-stage build
FROM node:20.11-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci

FROM node:20.11-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./
COPY . .

USER node
HEALTHCHECK --interval=30s --timeout=3s CMD node healthcheck.js
CMD ["node", "server.js"]
```

## 🚫 Example: Failing Dockerfile

```dockerfile
FROM node:latest        # ❌ unpinned version
WORKDIR /app
COPY . .                # ❌ no .dockerignore
# ❌ single-stage build
# ❌ no USER statement
# ❌ no HEALTHCHECK
CMD ["node", "server.js"]
```

## 🔧 Inputs

| Input | Default | Description |
|-------|---------|-------------|
| `dockerfile-path` | `./Dockerfile` | Path to Dockerfile to check |
| `strict` | `false` | Treat warnings (2-5) as errors |
| `github-token` | `github.token` | GitHub token for reviewdog |

## 📋 Check Behavior

**Default Mode** (`strict: false`):
- Check 1 (Pinned versions): **Required** ❌
- Checks 2-5 (Others): **Warnings only** ⚠️

**Strict Mode** (`strict: true`):
- All checks: **Required** ❌

## 🏗️ Architecture

Each check is a separate script:
- `check-pinned-versions.sh` — FROM statements
- `check-dockerignore.sh` — .dockerignore presence
- `check-multistage.sh` — Multi-stage detection
- `check-nonroot-user.sh` — USER directive
- `check-healthcheck.sh` — HEALTHCHECK directive

`run.sh` orchestrates all checks and pipes output to reviewdog for inline GitHub annotations.

## 📝 License

MIT
