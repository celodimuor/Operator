---
owner: operator-engineering
last_verified: 2026-10-04
review_every_days: 90
applies_to: ["operator/docs/cleanroom/**"]
status: current
---

# Clean-room functional specifications

Rules and template for the functional spec that must exist before any enterprise-parity feature is built. Policy and controls: [ADR 0003](../adr/0003-clean-room-policy.md). The charter makes this non-negotiable (`operator/AGENTS.md`, rule 1).

The point of a spec is evidence: a dated, sourced description of what the feature does for users, written without exposure to the licensed code, from which Operator's own design follows.

## When a spec is required

Before the first line of code for any feature that Chatwoot ships in its enterprise edition (the parity list in the plan: audit logs, roles and permissions, SLA, capacity and balanced assignment, required attributes on resolve, CSAT review notes, campaign analytics, conversation monitors, SSO, white-label, advanced search). One file per feature: `operator/docs/cleanroom/<feature>.md`, kebab-case, for example `audit-logs.md`. The file merges before or together with, never after, the code it governs. CI checks that every parity module under `operator/app` has a matching spec with at least one cited public source.

## Allowed sources

- Chatwoot public documentation and help centre pages, as published.
- The public changelog and release notes.
- The public API reference and published OpenAPI descriptions.
- The MIT-licensed code and UI of the Chatwoot core (everything outside the enterprise trees), including the MIT Vue screens and the extension points the core already exposes. Read it to learn how Operator can attach, not to copy gated screens (ADR 0003: parity features use their own tables, controllers and screens).
- Competitor products: their public documentation, marketing pages and user-visible behaviour, used under their terms of service.
- Standards and specifications (for example RFCs, OpenID Connect, SAML, WCAG) and regulations.

## Forbidden sources

- The enterprise directory, or its spec directory, in any version of the repository, in any form: working tree, git history, archives, tarballs, diffs, blame, mirrors, forks, vendored copies.
- Enterprise code on GitHub, anywhere: files, pull request diffs, commits, issues or discussions that quote it, gists, search results, or AI tools summarising it.
- Decompiled, scraped or paraphrased enterprise behaviour: deriving an exact structure (tables, columns, class or method names, query shapes, error strings) from the licensed code rather than from user-visible behaviour.
- Quotations from the above, even short ones, and copy-pasting UI copy verbatim from any product.
- Another person's or agent's notes that were themselves derived from forbidden sources.

If you cannot tell whether a source is allowed, it is not. Leave it out.

### Contamination protocol

If you see enterprise code by accident (a diff, a search hit, a stack trace, a pasted snippet): stop, do not write or review that spec, record what was seen and where in an issue labelled `needs-human`, and hand the spec to someone who has not seen it. Do not try to "unsee it" by writing around it.

## How to write a spec

- Describe observable behaviour, not code. Use your own vocabulary and names; Operator tables are `operator_*`, routes `/operator/...`, i18n keys `OPERATOR.*` (see [ADR 0002](../adr/0002-naming-and-prefixing.md)).
- Every statement in the behaviour section carries a citation id pointing at the Sources table. A statement without a source is either removed or moved to the Operator design section as our own decision, marked as such.
- Write requirements as testable statements; they become the red specs.
- Prefer a smaller feature that is fully sourced over a larger one that is guessed.

## Template

Copy this into `operator/docs/cleanroom/<feature>.md`.

````markdown
---
owner: operator-engineering
last_verified: YYYY-MM-DD
review_every_days: 90
applies_to: ["operator/app/**/<feature>/**"]
status: draft          # draft while being written; current once reviewed
---

# Clean-room spec: <feature name>

## Purpose

One paragraph: the user problem this feature solves and for whom (agent, admin, customer). No implementation.

## User-facing behaviour (from public sources)

Numbered, testable statements, each ending with its citation, for example "An administrator can ... [S1][S3]".

1. ...
2. ...

Cover: who can use it, what they see, the main flows, limits and defaults, notifications, reports, permissions, failure and empty states, and the API surface visible in the public API reference.

## Data the feature needs

Information the behaviour above requires, expressed as entities and attributes in plain language (what must be remembered, per account, for how long, who can see it). Data classes (public, internal, personal, secret). No table or column names yet, and nothing derived from the licensed code.

## Operator design

Our own design: tables (`operator_*`, `account_id NOT NULL`), services (`VerbNoun`), seams in the Seam Register, controllers under `/operator`, Vue screens, flags (`op_*`), entitlements, events, jobs, telemetry. Link the ADR for any architectural choice. Clearly separate our decisions from sourced behaviour.

## Out of scope

What this feature deliberately does not do, including behaviour from sources we choose not to match.

## Sources

| ID | Source (title) | URL | Type | Accessed | Used for |
|---|---|---|---|---|---|
| S1 | ... | https://... | public docs / help centre / changelog / API reference / MIT code / competitor / standard | YYYY-MM-DD | statements 1, 2 |

Type is one of the allowed categories. Every row has a URL (or a repository path for MIT code) and an access date.

## Attestation

Written without access to Chatwoot enterprise source

Author: <agent or person>, <YYYY-MM-DD>
````

## Review rule

The reviewer agent checks the Sources table before approving any PR that adds or changes a spec, or that adds parity code. It verifies, and requests changes if any check fails:

1. The spec file exists and was merged before, or in the same PR as, the code (commit order is visible).
2. The Sources table has at least one row; every row has an ID, a URL or repository path, a type from the allowed list, and an access date that is not after the spec date.
3. Every statement in the behaviour section cites at least one row, and every row is cited.
4. No URL or path points into the forbidden sources: nothing under the enterprise directories, no repository URL whose path contains `enterprise`, no mirrors or forks of Chatwoot, no third-party pages that quote enterprise code.
5. MIT code citations are repository paths outside the enterprise trees, not copied into the spec.
6. The Operator design names nothing copied from outside sources: no `Enterprise::` constants, no identifiers that appear only in the licensed code.
7. The attestation line is present and reads exactly "Written without access to Chatwoot enterprise source".
8. The PR description carries the clean-room attestation checkbox (ADR 0003).

The reviewer states in its approval that the sources table was checked. A PR with parity code and no spec cannot merge; the clean-room guard and references spec in CI also fail it.

## Index

One line per spec as they are written, kept in alphabetical order. Empty until the first parity feature starts.

| Feature | Spec | Status |
|---|---|---|
| (none yet) | | |
