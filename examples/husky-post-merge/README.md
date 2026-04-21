# Husky `post-merge` drop-in

Auto-refreshes agent skills when an engineer pulls updates. Fires only for engineers who have opted into husky hooks via the consuming repo's installer command (e.g. `yarn githooks:install` in `metamask-extension`).

## Install

1. Copy `post-merge` into the consuming repo at `.husky/post-merge` and make it executable:

   ```bash
   cp examples/husky-post-merge/post-merge <consuming-repo>/.husky/post-merge
   chmod +x <consuming-repo>/.husky/post-merge
   ```

2. Confirm the consuming repo already has:
   - `husky` as a devDependency
   - A `yarn skills:sync` script in `package.json`
   - A hook installer command in README (e.g. `yarn githooks:install` mapped to `husky install`)

3. Engineers opt in with the existing command:

   ```bash
   yarn githooks:install
   ```

## Behavior

| Event | Action |
|---|---|
| `git pull` / `git merge` with fresh VERSION (<7d) | No-op |
| `git pull` / `git merge` with stale VERSION (≥7d) | Runs `yarn skills:sync` |
| `git pull` / `git merge` with no VERSION file | Runs `yarn skills:sync` |
| `SKILLS_SKIP_AUTOSYNC=1` in env | Skipped silently |

## Updating the README

When dropping this hook into a repo, update its README to mention skills alongside existing hook behavior. Example for `metamask-extension`:

```markdown
## Git Hooks

To get feedback from fitness functions before commits **and to auto-refresh
[agent skills](./docs/agent-skills.md) when you `git pull`**, install our git
hooks with Husky:

$ yarn githooks:install

Active hooks:
- `pre-commit` — `yarn fitness-functions pre-commit-hook`
- `post-merge` — refresh agent skills if `.skills/VERSION` is >7 days stale
```

## Why `post-merge`, not `postinstall`

- `postinstall` fires in CI, on every install — wasteful and rate-limit-prone.
- `post-merge` fires only when repo state actually changed via merge/pull — the moment when skill staleness is most likely.
- Engineers who never `git pull` (e.g. forks, long-lived branches) won't auto-sync. They run `yarn skills:sync` manually; staleness warnings surface via `/remember`.
