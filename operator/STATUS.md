# Operator status

Updated: 2026-10-04 by the orchestrator.

## Milestone

Phase 0, Foundation. Target exit: engine boots with zero `Enterprise`
constants, upstream FOSS spec matrix green, Operator specs green on CI,
branded installation, docs system live, first upstream merge rehearsal.

## In flight

- Foundation PR: enterprise removal, engine skeleton, seam registry, hub seam,
  tombstone routes, branding, spec harness, CI, charter, day-one docs.

## Blocked

- Upstream `security-scan` job fails on a pre-existing `rack-proxy 0.7.7`
  advisory (GHSA-42qh-8mx8-7wqm) in Chatwoot v4.18.0's lockfile. Not a required
  check. Follow-up: bump `rack-proxy` to >= 1.0.3 once a Ruby toolchain is
  available to re-lock.
- Local Docker loop: Docker Desktop is stuck behind an "Update Failed" dialog
  (its auto-update hit a locked file). The engine will not start until a human
  clicks Continue in that dialog. Verification runs on GitHub Actions meanwhile.

## Pending human decisions (`needs-human`)

1. Public fork versus private repository. GitHub cannot make a fork private;
   private means a fresh repository with all refs pushed and `upstream` kept
   as a remote. Recommendation: private, before product code lands.
2. Accounts to open: AWS, Meta Business (WhatsApp test numbers), Paystack and
   Flutterwave test mode, Termii and Africa's Talking sandboxes, Smile ID and
   Dojah sandboxes, Vercel AI Gateway key and budget, Resend domain, Sentry,
   Langfuse.
3. Brand assets: Operator logo (light, dark, thumbnail) and brand URLs. Until
   provided, the installation name and brand name read "Operator" while the
   logo files are still Chatwoot's defaults.
4. Legal review of the clean-room policy document and NDPA disclosures.
