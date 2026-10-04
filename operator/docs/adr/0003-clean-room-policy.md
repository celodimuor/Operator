---
status: accepted
date: 2026-10-04
deciders: Operator engineering
---

# 0003. Clean-room policy for enterprise-equivalent features

## Context and Problem Statement

Chatwoot's repository is MIT-licensed except `enterprise/` (and its specs in `spec/enterprise/`), which carry a separate enterprise licence that requires a paid subscription for production use and claims modifications. That directory holds AI (Captain), SLA, audit logs, custom roles, SAML, capacity assignment, voice and branding. Operator must reach feature parity without ever using, copying, translating or being shaped by that code. How do we make the clean room airtight rather than a convention?

## Decision Drivers

- No enterprise licence, ever, for any Operator deployment (SaaS or self-hosted).
- Humans and agents must be unable to read enterprise source by accident.
- Contamination must be detected by CI, not by memory.
- The policy must survive every upstream merge, since upstream re-adds `enterprise/` each time.
- Parity features must be demonstrably independent in expression.

## Considered Options

1. Keep `enterprise/` and set `DISABLE_ENTERPRISE=true`.
2. Keep `enterprise/` but forbid reading it by convention.
3. Delete `enterprise/` and `spec/enterprise/`, re-delete on every merge, deny read access, guard in CI, and start every parity feature from a public-source functional spec.

## Decision Outcome

Chosen option: **3**.

| Control | Mechanism |
|---|---|
| Removal | `enterprise/` and `spec/enterprise/` deleted from the fork (OT-000) |
| Re-application | `operator/bin/upstream_resolve` (planned; invoked by `operator/bin/upstream_merge`) re-deletes both directories on every upstream merge before resolving conflicts |
| Read denial | `.claude/settings.json` denies `Read`, `Grep`, `Glob` and shell access to `enterprise/**` and `spec/enterprise/**` |
| CI existence guard | Build fails if either directory exists |
| CI reference guard | Build fails if anything under `operator/` references `Enterprise::` or the path `enterprise/` (this ADR and other policy docs are allow-listed by exact path) |
| Boot guard | Boot check asserts zero `Enterprise` constants are loaded |
| Functional spec first | Every enterprise-equivalent feature begins with `operator/docs/cleanroom/<feature>.md`, written only from public sources (product docs, marketing pages, public API docs, user-visible behaviour), each source cited by URL |
| No upstream browsing | Agents and contributors never open upstream enterprise source on GitHub or any mirror, including diffs and blame |
| Own tables and screens | Parity features use `operator_*` tables, controllers under `/operator`, and Operator Vue screens; MIT core screens gated to enterprise/cloud in router metadata are not reused |
| PR attestation | PR template includes a clean-room attestation checkbox for parity work |

Legal basis, briefly: the core is MIT-licensed and may be used, modified and sold freely with the notice preserved (`NOTICE` file). The enterprise licence governs the enterprise code itself, its expression, not the functionality it implements. Features such as SLA policies, audit logs or role-based permissions are ideas and are not protected by a copyright licence; an independent implementation written from public descriptions, with its own data model and screens, does not derive from the licensed code. Legal review of this policy is a pending human decision (plan section 12); this ADR is engineering policy, not legal advice.

### Consequences

- Good: contamination requires deliberately defeating three controls (deletion, read denial, CI grep).
- Good: each parity feature has a dated, sourced spec that documents independent creation.
- Good: own tables mean no schema coupling to enterprise migrations upstream may ship.
- Bad: core code paths that call into enterprise-only routes or constants must be neutralised (tombstone routes, ADR 0005).
- Bad: parity takes longer than porting; accepted.
- Bad: every upstream merge produces delete/modify conflicts under `enterprise/`; resolved mechanically by the script.

## Confirmation

| Check | CI job |
|---|---|
| `enterprise/` and `spec/enterprise/` absent | clean-room guard in `architecture` |
| No `Enterprise::` or `enterprise/` reference under `operator/` outside the allow-list | clean-room guard in `architecture` |
| Zero `Enterprise` constants at boot | `core-specs` boot check |
| Every parity module under `operator/app` has a matching `operator/docs/cleanroom/<feature>.md` with at least one cited public source | references spec in `docs` |
| Upstream merge PRs run the guard after `upstream_resolve` | `op-upstream-watch.yml` and merge gate |
