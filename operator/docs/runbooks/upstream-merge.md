---
owner: operator-engineering
last_verified: 2026-10-04
review_every_days: 30
applies_to: ["operator/bin/upstream_*", "operator/UPSTREAM_BASE", "operator/docs/upstream-touches.yml"]
status: current
---

# Runbook: merge a Chatwoot release tag

How Operator takes a Chatwoot release into `main`. Follow it top to bottom. The merge is mechanical by design: Operator lives in `operator/`, core edits are one-line logged touches (`operator/docs/upstream-touches.yml`), and the enterprise trees are re-deleted by script. Background: [ADR 0001](../adr/0001-extension-mechanism.md), [ADR 0003](../adr/0003-clean-room-policy.md), [ADR 0005](../adr/0005-routes-precedence.md).

## Rules

- Merge release tags only, never `develop` or any other branch of upstream.
- Merge within 7 days of a minor release (`vX.Y.0`) and within 48 hours of a security release. Patch releases ride the next merge unless they are security releases.
- One tag per PR. If several tags are due, merge them oldest first, one PR each.
- Use a merge commit. Never squash and never rebase the sync branch; squashing destroys the ancestry that makes the next merge small. If `main` moves while the PR is open, merge `origin/main` into the sync branch.
- Never read anything under the enterprise trees, including conflict markers. `upstream_resolve` removes them before you look at any conflict.
- Conflict budget: at most 10 non-mechanical conflicted files and 4 hours of work. Mechanical files (`db/schema.rb`, `Gemfile.lock`, `pnpm-lock.yaml`) and the enterprise trees do not count. See [When the conflict budget is exceeded](#when-the-conflict-budget-is-exceeded). This is separate from the core touch budget in `operator/docs/upstream-touches.yml` (12 non-mechanical files carrying an OT marker).

`operator/bin/upstream_merge` (planned) will wrap steps 1 to 9. Until it exists, run the commands below by hand; they are the specification for that script.

## Prerequisites

- Clean working tree on a machine that can run the specs. This repository's Windows host has no Ruby; use the Docker Compose devcontainer or WSL, and let GitHub Actions run the full matrix.
- `gh` authenticated; the `upstream-sync` label exists (create it once with `gh label create upstream-sync` if missing).
- Start a stopwatch. Time spent is part of the report.

## Procedure

Set the tag once and reuse the variables in every step.

```bash
export TAG=v4.19.0                       # the release tag to merge
export BRANCH="upstream/sync-$TAG"
export STARTED=$(date +%s)
```

### 1. Fetch and sanity-check the tag

```bash
git fetch origin
git fetch upstream --tags
git rev-parse "$TAG^{commit}"                                   # must resolve
git merge-base --is-ancestor "$(cat operator/UPSTREAM_BASE)" "$TAG" && echo "tag descends from our base"
git log --oneline "$(cat operator/UPSTREAM_BASE)..$TAG" | wc -l  # commits to be merged (for the report)
```

If the tag does not descend from the current base, stop: upstream rewrote history or the base is wrong. File an issue labelled `needs-human`.

### 2. Branch from `origin/main`

```bash
git switch -c "$BRANCH" origin/main
```

### 3. Start the merge without committing

```bash
git merge --no-ff --no-commit "$TAG"
```

Expect conflicts. Do not resolve anything yet.

### 4. Re-delete the enterprise trees

```bash
operator/bin/upstream_resolve
git ls-files enterprise spec/enterprise | wc -l     # must print 0
test ! -e enterprise && test ! -e spec/enterprise && echo "enterprise trees absent"
```

`upstream_resolve` removes `enterprise/` and `spec/enterprise/` from the index and the working tree, which also clears their delete/modify conflicts. It is idempotent.

### 5. Record the remaining conflicts and classify them

```bash
LIST="$(git rev-parse --git-dir)/upstream-conflicts.txt"
MECHANICAL='^(db/schema\.rb|Gemfile\.lock|pnpm-lock\.yaml)$'
git diff --name-only --diff-filter=U > "$LIST"
echo "mechanical:";     grep -E  "$MECHANICAL" "$LIST" || true
echo "non-mechanical:"; grep -Ev "$MECHANICAL" "$LIST" || true
grep -Evc "$MECHANICAL" "$LIST"                 # count against the budget of 10
```

Keep this list; it feeds the report.

### 6. Resolve the mechanical conflicts

Take upstream's side, then regenerate. Never hand-merge these files.

`db/schema.rb`: regenerate from migrations so Operator tables and upstream tables are both present.

```bash
git checkout --theirs db/schema.rb
RAILS_ENV=test bundle exec rake db:drop db:create db:schema:load db:migrate
git add db/schema.rb
grep -c 'create_table "operator_' db/schema.rb      # must be non-zero once Operator tables exist
```

`Gemfile.lock`:

```bash
git checkout --theirs Gemfile.lock
bundle install
git add Gemfile.lock
```

`pnpm-lock.yaml`:

```bash
git checkout --theirs pnpm-lock.yaml
pnpm install
git add pnpm-lock.yaml
```

If `Gemfile` itself conflicts, keep both sides: upstream's new gems plus the single line `eval_gemfile 'operator/Gemfile'` marked `OPERATOR-TOUCH: OT-001`, then re-run `bundle install`.

### 7. Resolve the non-mechanical conflicts

Every conflicted core file should be one we touched (see `operator/docs/upstream-touches.yml`) or a file whose contents moved under one of our one-line touches.

1. Take upstream's version of the file: `git checkout --theirs path/to/file`.
2. Re-apply our one-line touch from the register entry, keeping the `OPERATOR-TOUCH: OT-NNN` marker.
3. `git add path/to/file`.
4. If the file is not in the register, we have an unlogged edit: take upstream's version, and open an issue to move that behaviour into `operator/` (see the budget section).

Note the time each file takes. When the count passes 10 files or the clock passes 4 hours, stop resolving by hand and read [When the conflict budget is exceeded](#when-the-conflict-budget-is-exceeded).

Confirm nothing is left unresolved and no markers remain:

```bash
git diff --name-only --diff-filter=U            # must print nothing
git grep -nE '^(<<<<<<<|=======|>>>>>>>)( |$)' -- . ':!operator/docs' || echo "no conflict markers"
```

### 8. Verify

Run everything; each command must pass before you continue. Where the full core suite is too heavy locally, push the branch (step 11) and read the sharded CI result instead, but never skip it.

```bash
bundle exec rspec spec                       # core suite (CI shards it)
bundle exec rspec operator/spec/seams        # seam guards
bundle exec rspec operator/spec              # full Operator suite
pnpm test                                    # frontend tests
bundle exec rake operator:docs:generate      # (planned) regenerate generated docs, expect no stale diff afterwards
```

Failing seam guard: see [When a seam guard fails](#when-a-seam-guard-fails).

### 9. Review and refresh the core route snapshot

`operator/spec/architecture/core_routes_snapshot_spec.rb` fails when upstream adds or removes a core route. Do not refresh the snapshot to make it pass. Review first:

```bash
bundle exec rspec operator/spec/architecture/core_routes_snapshot_spec.rb   # lists added and removed routes
```

For each **added** route, check whether its controller exists in the MIT tree. You do not need, and must not use, the enterprise trees for this:

```bash
test -f app/controllers/api/v1/accounts/example_controller.rb && echo "MIT route" || echo "no controller in the MIT tree"
```

- Controller present: ordinary core route. Accept it.
- Controller absent: the route belongs to the removed enterprise code and would raise at request time. Add its path to `Operator::TombstoneRoutes` in `operator/lib/operator/tombstone_routes.rb` (`ACCOUNT_PATHS` or `GLOBAL_PATHS`, ADR 0005), and cover it in the tombstone request spec.

For each **removed** route, check whether a tombstone existed for it and drop the tombstone if the path is gone upstream for good.

Only after that review against the tombstone list, refresh and inspect the diff:

```bash
bundle exec rake operator:routes:snapshot
git diff operator/spec/snapshots/core_routes.txt
git add operator/spec/snapshots/core_routes.txt
bundle exec rspec operator/spec/architecture operator/spec/requests
```

Summarise the diff (routes added, removed, tombstoned) for the report.

### 10. Update the base, commit, audit

`operator/bin/touch_audit` diffs `UPSTREAM_BASE` against `HEAD`, so the base must be updated and the merge committed before the audit means anything.

```bash
git rev-parse "$TAG^{commit}" > operator/UPSTREAM_BASE
git add operator/UPSTREAM_BASE operator/docs
git commit -m "chore(upstream): merge chatwoot $TAG"
ruby operator/bin/touch_audit                 # must print: touch audit: N changed paths, all accounted for
```

If the audit lists unexpected core files, a core edit slipped in: either it is a legitimate new touch (add an OT entry, one line, within budget) or it is an upstream change we wrongly kept; fix it and add a follow-up commit. Also re-check that every `status: applied` entry still has its marker; line numbers quoted in register entries (for example OT-004) may need updating.

Re-run step 4's `test ! -e enterprise ...` check and bump `last_verified` on any doc whose `applies_to` matched files this merge touched.

### 11. Open the PR and enable auto-merge with a merge commit

```bash
git push -u origin "$BRANCH"
export MINUTES=$(( ( $(date +%s) - STARTED ) / 60 ))
gh pr create --base main --head "$BRANCH" \
  --title "chore(upstream): merge chatwoot $TAG" \
  --label upstream-sync \
  --body-file /path/to/merge-report.md          # filled from the template below
gh pr merge --auto --merge                      # merge commit; never --squash, never --rebase
```

CI is the only gate: `architecture guards` (clean room and touch budget) and `operator specs` in `.github/workflows/op-ci.yml`, plus the rest of the required checks. Watch it and fix root causes; never weaken a check.

After it merges, confirm the ancestry was preserved:

```bash
git fetch origin
git cat-file -p origin/main | grep -c '^parent'    # must print 2
git merge-base --is-ancestor "$TAG" origin/main && echo "tag is an ancestor of main"
```

## When a seam guard fails

A failing `operator/spec/seams` spec means upstream changed something Operator depends on. This is the system working.

1. Read the failure: missing method, changed signature, or the Operator module no longer precedes the core class in `ancestors`.
2. Find what changed in core with `git log -p "$(cat operator/UPSTREAM_BASE)..$TAG" -- path/to/core/file`. Never run this against the enterprise trees.
3. Adapt the seam inside `operator/` (the seam module, the Operator service it delegates to, and the guard spec's snapshotted signature). Keep the seam within 30 lines and delegating only.
4. Do not edit core to make a seam work beyond the register. If the fix needs a core touch, add or amend an OT entry only when it is one line and the register stays inside its budget. If it needs more, stop: label an issue `needs-human` and add a line to `operator/STATUS.md` (charter: a fix that needs core touches beyond budget).
5. If a core method we depend on vanished and the replacement changes the design, write an ADR in `operator/docs/adr/` in the same PR (next free number, MADR format; see `operator/docs/adr/README.md`) explaining the new seam and what was rejected.
6. Re-run `bundle exec rspec operator/spec/seams` and the full Operator suite.

## When the conflict budget is exceeded

More than 10 non-mechanical files, or more than 4 hours. Do not abandon the merge and do not skip tags.

1. Finish resolving by taking upstream's version of each remaining file and re-applying only the registered one-line touches. Everything else we had changed in core is dropped from core for now.
2. If dropping it breaks a spec, restore the behaviour in `operator/` through a seam (previous section) rather than in core.
3. Land the merge once CI is green. Falling behind upstream costs more than a late merge.
4. For each offending customisation file an issue labelled `upstream-debt` (create the label if missing): which core file, what we changed, why it conflicted, and the proposed seam or `operator/` replacement. A repeat offender is moved into `operator/` before the next merge.
5. Put the overrun, file list and time in the merge report. A budget overrun is a signal about the architecture, not about the person merging.

## Rollback

- Before the PR merges: abandon it. Run `git merge --abort` if the merge is still open; otherwise close the PR and delete the branch (`git switch main`, `git branch -D "$BRANCH"`, `git push origin --delete "$BRANCH"`). `operator/UPSTREAM_BASE` on `main` is unchanged, so nothing else needs undoing.
- After the PR merged and production is affected: use the release train rollback in the rollback runbook (`operator/docs/runbooks/rollback.md`, planned) to redeploy the previous image digest first. Then fix forward where possible.
- To remove the merge from `main` itself, open a PR that reverts the merge commit: `git revert -m 1 <merge-sha>` (force pushes are blocked). The revert restores `operator/UPSTREAM_BASE`. To merge the same tag again later, first revert the revert; otherwise git treats the tag's changes as already merged and skips them.
- Record the reason in the merge report and in `operator/STATUS.md`.

## Merge report template

Paste into the PR description, filled in. Keep it short.

```markdown
## Upstream merge report

| Field | Value |
|---|---|
| Tag | vX.Y.Z |
| Previous base | <sha from operator/UPSTREAM_BASE before the merge> |
| New base | <sha from git rev-parse vX.Y.Z^{commit}> |
| Release type | minor / patch / security |
| Commits merged | N |
| Merged within window | yes / no (7 days minor, 48 h security) |

### Conflicts

| Class | Count | Files |
|---|---|---|
| Mechanical | N | db/schema.rb, Gemfile.lock, pnpm-lock.yaml |
| Non-mechanical | N of 10 | one per line, with the OT id if any |
| Enterprise trees | removed by operator/bin/upstream_resolve | |

### Seams affected

| Seam | What changed upstream | Action |
|---|---|---|
| none / name | | adapted in operator/ / ADR NNNN |

### Route snapshot diff

Added: N (of which tombstoned: N). Removed: N. Notable routes:

### Verification

Core suite, seam guards, Operator suite, frontend tests, touch audit: pass / fail with links.

### Time spent

N minutes (budget 240). Overrun issues filed: #...
```
