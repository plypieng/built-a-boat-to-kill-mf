# Week 2 Reward Loop Design

Date: 2026-03-08

## Overview

This document captures the approved Week 2 MVP slice for the desktop-first Godot prototype. The goal is to make extracted rewards immediately change what the crew can build next without turning the hangar into a deep crafting or tech-tree system.

The approved direction is to unlock new block types first, not to add upgrade tiers for the existing block set. The reward loop stays intentionally small: successful runs bank gold and salvage into a shared team progression state, the hangar exposes a compact unlock panel, and new parts become available in the shared builder palette the moment the crew buys them.

## Approved Direction

Use a `new block unlocks first` progression slice.

Why this is the right fit:

- it makes rewards matter right away
- it changes the shared builder in a visible way
- it avoids a balance-heavy upgrade tree
- it keeps Week 2 aligned with the MVP goal of fast, readable progress

This week deliberately avoids:

- consumable part inventory
- per-part crafting quantities
- branching tech trees
- random stat rolls
- deep crafting dependencies

## Reward Loop Goal

One successful extraction should give the crew a meaningful reason to rebuild before the next launch.

The desired emotional flow is:

1. extract cargo
2. return to hangar
3. see shared resources increase
4. unlock a new part
5. immediately use that part in the shared builder
6. launch a noticeably different boat

## Shared Progression Model

Because the hangar boat is already a shared authoritative blueprint, unlocks should also belong to the shared team session.

For Week 2:

- the dedicated server owns the unlock state
- the unlock state is persisted through the host/server profile
- connected clients receive the current unlock and currency snapshot from the server
- the hangar store validates purchases on the server

This is intentionally a `manual-hosted shared progression` model, not a player-account model. It matches the current MVP goal and avoids backend work.

## Currency Model

Keep the current extraction rewards:

- `gold`
- `salvage`

Use them as follows:

- `gold` is the main unlock spend
- `salvage` is a light secondary gate for stronger parts

The team should never need to micromanage ingredient counts yet. Week 2 should feel like unlocking toy pieces for the shared boat, not doing spreadsheet crafting.

## Unlock Catalog

The first store should unlock a small set of new parts with very clear roles.

Recommended Week 2 unlocks:

- `reinforced_hull`
  - higher max HP and better buoyancy than the base hull
  - heavier and more expensive
  - good for crews that want safer extractions
- `twin_engine`
  - stronger thrust than the base engine
  - heavier and slightly more fragile
  - good for aggressive salvage or faster extraction lines
- `stabilizer`
  - utility-focused support block
  - stronger brace and repair contribution than the base utility block
  - good for crews leaning into survivability and support roles

These three unlocks create early strategic variety without needing a huge catalog.

## Hangar UX

The hangar should gain a compact store panel, not a full shop scene.

Recommended UI behavior:

- show team totals for gold and salvage
- show a list of unlockable parts
- show one selected part’s:
  - name
  - short description
  - stat summary
  - unlock cost
  - unlocked / locked / affordable state
- allow purchase directly from the hangar
- update the builder palette immediately after purchase

Locked parts should still be visible in the store so the crew can plan toward them.

## Builder Integration

The builder palette should only include currently unlocked parts.

Rules:

- base parts remain available from the start:
  - core
  - hull
  - engine
  - cargo
  - utility
  - structure
- newly unlocked parts appear in the palette immediately
- the server rejects placement of locked parts even if a client tries to request them directly

This keeps the progression honest while preserving the live shared-building flow.

## Run Integration

The run loop should not need a large refactor for Week 2.

The new parts should work through the existing derived-stat path:

- stronger hull parts increase survivability and buoyancy margin
- better engines increase top speed
- stronger support parts raise brace and repair capacity

Because the runtime already derives stats from block definitions, the first unlocks can slot into the current run model cleanly.

## Persistence

The shared team progression should be saved in the dock profile alongside:

- total gold
- total salvage
- run counts
- last run summary

Week 2 should add:

- unlocked block ids
- last unlock summary

That gives the hangar enough information to show “what changed” after the latest run.

## Error Handling

Purchases should fail safely and clearly if:

- the block is already unlocked
- the block id does not exist
- the team cannot afford the cost
- the session is not in the hangar

Invalid purchase attempts should not mutate the shared profile or blueprint.

## Testing

Week 2 verification should cover:

- unlock state loads from the host profile
- a successful run increases shared resources
- buying a block reduces the shared currency totals
- the unlocked part appears in the palette immediately
- locked parts cannot be placed before purchase
- purchased parts affect derived boat stats
- hangar to run still works with the newly unlocked parts

## Success Criteria

Week 2 is complete when:

- one successful run can produce a meaningful unlock
- the hangar shows shared team resources and unlock choices clearly
- the shared builder palette updates after purchase
- newly unlocked blocks affect boat stats and run behavior
- the full hangar -> run -> hangar loop still works cleanly
