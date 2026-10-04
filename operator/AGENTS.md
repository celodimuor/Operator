# Operator engineering charter

Read this before touching anything under `operator/` or any core file. For
Operator work it overrides the root `AGENTS.md`; in particular, specs are
mandatory here, and nothing in a spec is stubbed.

## Mission

Build Operator as a thin, fully tested extension of the Chatwoot MIT core.
Every change is followed to its logical conclusion: code, tests, docs,
telemetry, cleanup. No half-finished threads, no "later" comments.

## Non-negotiables

1. **Clean room.** Never read, quote, paraphrase or look up Chatwoot's
   `enterprise/` code, in this repo or on GitHub. Enterprise-equivalent
   features start from a public-source spec in `operator/docs/cleanroom/`.
2. **Nothing stubbed.** Specs run real PostgreSQL, Redis, Sidekiq, ActionCable,
   ActiveStorage and browsers. External providers are exercised through their
   sandboxes or through recorded real traffic. No `allow(...).to receive`,
   no `instance_double`, no hand-written HTTP stubs on Operator or core code.
3. **Core touches are one line each**, marked `# OPERATOR-TOUCH: OT-NNN`,
   logged in `operator/docs/upstream-touches.yml`, and inside the budget.
   Change core behaviour through `Operator::Seams`, never by editing core.
4. **Prefixes.** `Operator::` namespaces, `operator_` tables and queues,
   `/operator` routes, `op_` flags, `OPERATOR.*` i18n keys, `OPERATOR_` env.
5. **Docs stay live.** Regenerate `operator/docs/generated/`, update the docs
   whose `applies_to` globs you touched, bump `last_verified`.
6. **No bloat.** No new dependency without an ADR. No abstraction without two
   real users. Delete what you replace in the same change. Respect the size
   limits in `operator/docs/standards/`.
7. **Never weaken a check to make CI pass.** Fix the cause.

## Workflow for every change

1. Read the Seam Register, the relevant ADRs, domain docs and standards.
2. If the change is architectural, write or amend an ADR in the same PR.
3. API first: update `operator/swagger/` before the controller.
4. Red: write the failing spec at the right layer. Green: make it pass.
   Refactor: leave the code better than you found it.
5. Run the affected specs plus `operator/spec/seams` and the tenancy matrix.
6. Regenerate docs; update hand-written docs and their frontmatter.
7. Open a PR with a conventional title (`feat(billing): ...`) and the
   Definition of Done filled in. Enable auto-merge. Watch CI; fix root causes.

## Code

Service objects named `VerbNoun` with one public `call`; commands return
`Operator::Result`, queries never write. Expected outcomes are results, bugs
raise. Jobs are idempotent and declare their key. Webhooks verify the raw
body, persist to `operator_inbound_events`, acknowledge fast, process async.
Transactions never span external I/O; enqueue after commit. Every Operator
table has `account_id NOT NULL` and every endpoint goes through Pundit.
Vue: Composition API, components-next, Pinia, Tailwind only, lazy routes,
i18n for every string.

## Working with sub-agents

Give each sub-agent this file plus a self-contained brief: goal, acceptance
criteria, ADR ids, seams involved, file list, out of scope. One worktree,
branch, database and Redis index per implementer. Fan out only on disjoint
file sets. Sub-agents report in at most 300 words plus a PR link.

Model choice: opus for planning, ADRs, cross-module refactors, upstream
merges, security review and final review; sonnet for implementing specced
slices, tests and docs; haiku for mechanical work.

## Review before merge

An independent reviewer agent with fresh context runs the code-review skill
at high effort against: correctness and edge cases, tenancy scoping, authz,
N+1, transactions and after-commit, idempotency, error mapping, no stubs,
docs updated, abstraction justified, dead code removed, telemetry present.
Changes touching auth, identity, billing, webhooks, encryption, PII columns,
the safe HTTP client or policies also get the security-review skill.

## Stop and ask the human when

Legal or licence questions; terms or privacy text; any new paid service;
AI spend above 150% of budget or infra cost up more than 15% in a month;
destructive production data operations; creating external accounts or OAuth
grants; customer-visible pricing; a Sev1 incident; an upstream licence
change; a fix that needs core touches beyond budget; a product scope change.
Record it as an issue labelled `needs-human` and a line in `operator/STATUS.md`.

## Records

Technical decisions live in `operator/docs/adr/`. Product scope decisions
live in `operator/docs/product/decisions.md`. Progress lives in
`operator/STATUS.md`, updated by the orchestrator. Work items are GitHub
issues; every PR closes one.
