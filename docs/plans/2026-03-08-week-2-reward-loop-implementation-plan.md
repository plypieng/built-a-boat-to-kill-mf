# Week 2 Reward Loop Implementation Plan

Date: 2026-03-08
Depends on: `docs/plans/2026-03-08-week-2-reward-loop-design.md`

## Objective

Implement a small shared unlock/store loop that turns extracted rewards into new build options for the crew.

## Note

The `writing-plans` skill was not available in this session, so this file is the direct fallback implementation plan for the approved Week 2 design.

## Delivery Principle

Keep the economy intentionally small and visible. Week 2 should make the builder more interesting, not bury the prototype under progression complexity.

## Scope

- add server-owned shared progression state
- persist unlocks and shared resources through the dock profile
- add a small unlock catalog with three new parts
- add a compact hangar unlock panel
- gate the shared builder palette by unlock state

## Suggested Implementation Order

1. `Profile and catalog foundation`
   - extend `DockState` with unlocked block ids and last unlock summary
   - add unlock metadata to the block catalog

2. `Authoritative progression runtime`
   - add progression state and replication to `NetworkRuntime`
   - load progression from the host profile when the server starts
   - broadcast progression to clients on bootstrap and after purchases

3. `Purchase flow`
   - add a server-validated unlock request RPC
   - reject invalid or unaffordable purchases safely
   - persist successful unlocks and rebroadcast the progression snapshot

4. `Hangar UI`
   - add a compact store panel
   - show totals, selected unlock, cost, and status
   - allow purchase from the hangar
   - update the builder palette immediately after unlock

5. `Verification and docs`
   - update README and progress notes
   - run unlock-flow and hangar-to-run smoke checks

## Expected File Touches

- `autoload/dock_state.gd`
- `autoload/network_runtime.gd`
- `scenes/hangar/hangar.gd`
- `README.md`
- `progress.md`

## Suggested Verification

- headless server boot with shared progression state
- hangar purchase smoke for at least one unlock
- palette gating smoke before and after purchase
- build and launch smoke using a newly unlocked block
- regression check for hangar -> run -> hangar

## Risks

- do not split progression ownership between client and server
- do not let the store become a full-screen menu that overwhelms the hangar
- keep the unlock list short enough that the team can understand it at a glance
- preserve the existing deterministic smoke helpers while adding progression state
