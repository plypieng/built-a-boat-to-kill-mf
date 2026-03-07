# Live Co-op 3D Boat Builder Implementation Plan

Date: 2026-03-08
Depends on: `docs/plans/2026-03-08-live-coop-3d-boat-builder-design.md`

## Objective

Build a live co-op 3D block boat builder for the shared team boat, then feed that build into the current authoritative extraction loop with chunk-based detachment and sinking.

## Delivery Strategy

The builder should ship in narrow playable slices. Each slice should end with something the team can open, edit, or launch rather than infrastructure only.

## Milestone A: Shared Builder Foundation

### Goals

- Add a persistent shared boat blueprint
- Add live co-op 3D editing in the hangar
- Keep the editor authoritative and conflict-safe

### Tasks

- Add a persistent blueprint store to `DockState`
- Define block data and block definitions
- Add initial block palette:
  - core
  - hull
  - engine
  - cargo
  - utility
  - structure
- Add builder-mode state to the hangar scene
- Add a bounded 3D build volume
- Add cursor targeting and ghost preview
- Add place, remove, rotate, and block selection actions
- Add authoritative shared-edit RPC flow
- Add replicated blueprint updates for all connected editors
- Add simple edit rejection reasons

### Exit Criteria

- Two or more clients can edit the same shared boat live
- All valid edits replicate consistently
- Invalid or conflicting edits fail cleanly

## Milestone B: Builder Feedback And Seaworthiness

### Goals

- Make the hangar explain what the current design means
- Surface disconnected chunks before launch

### Tasks

- Add aggregate stat derivation from the blueprint
- Add hangar stat panel
- Add connectivity graph calculation in hangar
- Add `seaworthy` and `disconnected chunks detected` warnings
- Add loose-chunk launch preview text
- Add blueprint version display

### Exit Criteria

- Players can see the build update stats in real time
- Disconnected chunks are clearly identified before launch

## Milestone C: Run Startup From Blueprint

### Goals

- Launch the current extraction loop using the built boat
- Preserve the current run loop while replacing placeholder boat assumptions

### Tasks

- Snapshot blueprint version at run launch
- Build runtime chunk graph from the blueprint
- Select main active chunk
- Spawn disconnected non-main chunks as loose sinking pieces
- Derive runtime stats from the main chunk
- Replace placeholder boat defaults with derived values:
  - hull
  - speed
  - turn response
  - cargo capacity
  - repair supply capacity
  - brace effectiveness
- Replicate the built boat visuals in run

### Exit Criteria

- The run starts with the actual shared build
- Loose disconnected sections sink immediately if present
- Boat performance changes when the build changes

## Milestone D: Per-Block Runtime Damage

### Goals

- Make boat shape and damage materially matter during extraction

### Tasks

- Add per-block HP to runtime state
- Map hazard and collision damage into block hits
- Destroy blocks at zero HP
- Recompute connectivity after each destruction event
- Detach newly disconnected chunks
- Convert detached chunks into server-owned sinking debris
- Recompute aggregate stats after chunk loss
- Add visible damage and missing-block feedback

### Exit Criteria

- Impacts can remove blocks
- Chunk loss changes boat capability mid-run
- Detached chunks sink and no longer contribute stats

## Milestone E: Live Co-op Builder Hardening

### Goals

- Improve usability and multiplayer reliability

### Tasks

- Add smoother build camera controls
- Add clearer hover reservations and conflict feedback
- Add block palette polish
- Add save/load recovery checks
- Add build-session reconnect handling
- Add launch safety messaging for obviously bad builds

### Exit Criteria

- Builder editing feels stable with multiple collaborators
- Session recovery is reliable enough for repeated internal playtests

## Recommended Data Contracts

Freeze early schemas for:

- `BoatBlueprint`
- `BlockRecord`
- `BlockDefinition`
- `BuildSessionState`
- `BoatRuntimeBlockState`
- `RuntimeChunkState`
- run launch blueprint snapshot payload

## Technical Notes

### Connectivity

- Use 6-direction adjacency on the grid for first-pass connectivity
- Compute connected components in both hangar and run
- Keep main active chunk selection deterministic

### Runtime Simulation

- Keep one active controllable boat chunk
- Treat detached chunks as simplified sinking debris
- Avoid trying to make every detached chunk a full physical vessel

### Networking

- Clients send intent only
- Server validates occupancy, bounds, rotation, and blueprint version
- Blueprint replication should be explicit and measurable

## Suggested First Sprint

The first sprint should stop before runtime damage and focus on proving the shared builder itself.

### Sprint Scope

- persistent shared blueprint
- one dock builder mode
- place/remove/rotate in 3D
- live co-op replication
- block palette with initial six block types
- hangar stat panel
- disconnected chunk warning

### Sprint Exit Test

- launch two clients into the same dock
- edit the same shared boat live
- save the blueprint
- reload the dock and verify the boat layout persists
