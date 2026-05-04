<!-- @format -->

# Repository Style Guide

## Reviewer Behaviour

**Always propose concrete code changes.** For every issue, smell, or improvement identified
during a review, Gemini must provide an actionable code suggestion using GitHub's
suggestion block syntax:

```suggestion
// corrected code here
```

Observations without an accompanying code suggestion are not sufficient.
When a fix is non-trivial or spans multiple files, provide the corrected snippet
for each affected location and explain the rationale inline.

## Commit Messages

See [Commit Naming Skill](../skills/commit-naming/SKILL.md) for detailed guidelines on crafting Conventional Commit-compliant messages. Always ensure that any code change proposed includes a corresponding commit message suggestion that adheres to these standards.
