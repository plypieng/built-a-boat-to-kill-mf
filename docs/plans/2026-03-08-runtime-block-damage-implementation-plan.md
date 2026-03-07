# Runtime Block Damage Implementation Plan

Date: 2026-03-08
Depends on: `docs/plans/2026-03-08-runtime-block-damage-design.md`

## Objective

Make the built boat materially matter during runs by rendering the launched block layout, applying per-block damage, detaching disconnected chunks, and updating boat capability immediately when chunks are lost.

## Delivery Strategy

Ship this milestone in narrow slices that keep the run playable after each step.

## Milestone B1: Run-Time Block Rendering

### Goals

- Replace the placeholder run hull with the launched block boat
- Show disconnected launch chunks sinking immediately

### Tasks

- Snapshot the boat blueprint at run launch
- Build run-time block records from the snapshot
- Spawn block visuals in the run client
- Separate main-chunk visuals from loose launch chunks
- Add simple sinking presentation for loose chunks

### Exit Criteria

- The run shows the actual launched block boat
- Pre-disconnected chunks sink immediately at run start

## Milestone B2: Per-Block Runtime State

### Goals

- Add authoritative block and chunk state on the server

### Tasks

- Add runtime block HP state
- Add runtime chunk records
- Add main-chunk selection logic
- Add derived stat recomputation from the main chunk
- Replicate block and chunk state to clients

### Exit Criteria

- The server owns real block/chunk runtime state
- The main chunk is chosen deterministically

## Milestone B3: Localized Damage

### Goals

- Make collisions and salvage surges hit real blocks

### Tasks

- Compute impact points in boat-local space
- Find a nearest-block-centered damage cluster
- Apply weighted damage to 3 to 5 nearby blocks
- Add brace-adjusted event damage
- Destroy blocks at zero HP

### Exit Criteria

- Impacts damage a local block cluster
- Destroyed blocks disappear from the live boat

## Milestone B4: Connectivity And Detachment

### Goals

- Turn block loss into meaningful chunk loss

### Tasks

- Recompute connectivity after block destruction
- Detect detached chunks
- Promote a new main chunk when necessary
- Spawn detached chunk debris records
- Remove detached chunk stat contribution immediately
- Clamp cargo and repair capacity after chunk loss

### Exit Criteria

- Detached chunks sink
- Chunk loss immediately changes boat capability
- Cargo overflow can be lost when cargo chunks detach

## Milestone B5: UX And Validation

### Goals

- Make chunk loss readable and testable

### Tasks

- Add HUD lines for block count, cargo capacity, and cargo lost
- Add chunk-detached status messaging
- Add result-screen summaries for destroyed blocks, lost chunks, and cargo lost
- Add headless smoke tests for:
  - disconnected launch chunks
  - block destruction
  - chunk loss
  - cargo overflow loss
- Run at least one manual desktop play pass

### Exit Criteria

- Players can understand what they lost and why
- The run remains stable across automated and manual checks

## Suggested First Sprint

- run-time block rendering
- launch-time loose-chunk sinking
- runtime block records
- main-chunk stat recomputation
- one localized damage path for collision impacts

## Suggested First Sprint Exit Test

- launch a boat with disconnected blocks and verify they sink immediately
- collide into hazards and destroy visible blocks
- confirm chunk loss reduces speed or cargo capacity
- confirm the run remains synchronized for at least two clients
