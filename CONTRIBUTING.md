# Contributing to Velocity

## Git and GitHub workflow

Use small, focused branches and pull requests so changes stay reviewable and reversible.

### Branch naming

| Prefix | Use for |
|--------|---------|
| `issue/<number>-short-slug` | Work tied to a GitHub issue (preferred when an issue exists) |
| `feature/short-slug` | New product or UI capability without an issue yet |
| `fix/short-slug` | Bug fixes |
| `chore/short-slug` | Tooling, docs, project settings |

Examples: `issue/42-alarm-setup-validation`, `feature/map-search`, `fix/tab-bar-selection`.

### When to branch

1. **Before** implementing a non-trivial change: create a branch from up-to-date `main` (`git pull origin main` first).
2. **During** a Cursor plan or task: keep work on that branch; avoid mixing unrelated fixes.
3. **After** merge: delete the remote branch if GitHub does not auto-delete.

### Pull requests

- Open a PR against `main` when the branch is ready (or as draft for early feedback).
- Describe **what** changed and **why** in complete sentences; link `Fixes #123` or `Refs #123` when applicable.
- Keep PRs scoped: one feature or one bug fix per PR when practical.

### Issues and plans

- **GitHub Issues** are the durable record for bugs, features, and decisions. Prefer filing an issue before large efforts.
- **Cursor plans** are implementation guides: when a plan is accepted, create or update an issue summarizing scope, then implement on a named branch and close the loop in the PR description.

### Secrets

- Never commit API keys. Local Stitch MCP config belongs in `.cursor/mcp.json` (ignored); use [`.cursor/mcp.json.example`](.cursor/mcp.json.example) as the template.

### Xcode and assets

- Prefer the shared scheme under [`Velocity.xcodeproj/xcshareddata/xcschemes/`](Velocity.xcodeproj/xcshareddata/xcschemes/).
- Large binary assets: consider size impact on clone and CI before adding.

For product goals and architecture, see [AGENTS.md](AGENTS.md).
