# Engineering Bible

Authoritative engineering conventions for Project Ascend, layered on top of
`packages/docs/architecture.md`. Where the two overlap, this document wins
for product-behavior decisions; `architecture.md` remains authoritative for
system topology.

## Never rebuild working code to match new terminology

When a product document introduces a new name for something that already
exists and works (e.g. "Assistant" tab vs. the existing "Ascend" companion
screen), rename/relabel and extend — don't rewrite the underlying feature
from scratch. Preserve tests, preserve data, preserve working logic.

## Migrations

- Forward-only. Never edit or delete a shipped migration.
- Every new required field on an existing table ships nullable or with a
  default, so existing rows stay valid without a data backfill step being
  mandatory at deploy time.
- Any migration touching a table with real user data gets verified against
  both a fresh database and a database seeded with pre-migration-shaped
  rows (see `packages/docs/build-session-2.md` for the throwaway-database
  method already established and reused every session since).

## Idempotency and sync

All new offline-capable mutations reuse the existing shared idempotency
ledger (`services/api/src/common/idempotency/`) and, on the Flutter side,
the existing generic outbox (`apps/mobile/lib/core/sync/`). Do not build a
second sync mechanism — extend the shared one, and keep it free of
domain-specific logic (see `packages/docs/extension-points.md`).

## Entitlements

Capability checks (`isPremium`-style gating) go through a single
`CapabilityService`, never scattered `if (user.isPremium)` checks in
widgets or controllers. See `free-premium-policy.md` for what's actually
gated today (currently: nothing meaningful — see that document) and
`services/api/src/common/entitlements/` / `apps/mobile/lib/core/
entitlements/` for the implementation.

## Testing bar

A feature isn't done until:
- backend: unit tests for service logic with real business rules (not
  trivial getters), e2e tests for the HTTP contract including
  authorization and idempotency where relevant
- Flutter: widget/provider tests using the existing `Fake*Repository` /
  `createTestContainer` pattern in `test/helpers/` — never a real network
  call in a test
- `flutter analyze` / `pnpm api:lint` clean, no suppressed warnings
- the affected test suites actually run and pass — never described as
  passing without running them

## Documentation as source of truth

Every session's real, verified results go in a new
`packages/docs/build-session-N.md` — append-only, no retroactive editing
of a previous session's entry. Don't fabricate a result that wasn't
actually run.

## Product-doc precedence

Before implementing product-facing behavior (copy, flow, what's shown
where), read `packages/docs/product/`. Those documents override unstated
implementation assumptions. They do not override:
- security requirements
- applicable law (and legal-review-required drafts are marked as such —
  see `wellness-ethics-bible.md`'s Terms guidance)
- platform policy (App Store / Play Store rules)
- a verified technical constraint (e.g. "we don't have Google OAuth
  credentials configured" is a real constraint a product doc can't wish
  away — build the honest extension point instead, per
  `packages/docs/product/user-scenario-bible.md` Scenario 2)
