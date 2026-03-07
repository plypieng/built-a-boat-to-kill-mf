# Live Co-op 3D Boat Builder Design

Date: 2026-03-08

## Overview

This document captures the approved design for the next major milestone: a live co-op 3D boat builder in the hangar that feeds directly into the existing shared-boat extraction loop.

The milestone introduces a true block-built team boat that multiple players can edit together in real time. The builder uses freeform 3D placement inside a bounded build volume, 90-degree rotation, authoritative shared editing, and a versioned shared blueprint. Disconnected structures are allowed in the editor. If the crew launches with disconnected chunks, those chunks spawn as loose pieces and sink immediately at run start.

The runtime path for this milestone is a hybrid:

- per-block build and damage data
- chunk-based connectivity checks
- aggregate runtime stat derivation for the main connected boat
- detached chunk sinking without full rigid-body naval simulation for every piece

This preserves the game’s modular construction identity now while keeping multiplayer scope under control.

## Approved Product Decisions

- Builder style: full freeform block builder
- Editing mode: live co-op
- Boat ownership: one shared team boat blueprint
- Placement space: true 3D bounded build volume
- Rotation: 90-degree grid-aligned rotation only
- Builder connectivity rule: disconnected blocks are allowed
- Launch rule: disconnected chunks produce a warning but do not block launch
- Run-start behavior for disconnected chunks: they spawn as loose pieces and sink immediately
- Runtime destruction behavior: disconnected chunks detach and sink
- First runtime fidelity target: chunk-based detachment plus aggregate boat stat recomputation

## Goals

- Let friends co-build a weird, expressive team boat together in the hangar
- Make the custom build materially affect the current extraction loop
- Preserve a path toward deeper structural simulation later
- Keep live editing authoritative and multiplayer-safe
- Allow dramatic chunk loss and sinking without requiring full rigid-body vessel simulation for every fragment

## Non-Goals For This Milestone

- Material variants and cosmetic part skins
- Undo history beyond simple removal and re-placement
- Per-player build permissions or role locking
- Blueprint branch, merge, or version history UI
- Fully simulated fluid dynamics per block
- Fully drivable detached chunks
- Per-block interior traversal or character collision polish

## High-Level Architecture

The milestone adds a shared build layer between the dock/hangar and the run.

### Core Runtime Layers

- `Dock/Hangar Scene`
  The social and meta layer where players see persistent rewards, enter build mode, and launch runs
- `BuildSession`
  A server-authoritative shared editing session for one team blueprint
- `BoatBlueprint`
  Persistent block layout data used by hangar and run startup
- `BoatRuntime`
  The run-time instance derived from the blueprint, including chunk graph, block HP, sinking state, and aggregate stats

### Authority Model

- Clients send build intent such as place, remove, rotate, or change selected part
- The authoritative session validates the action
- The session mutates the blueprint and increments its version
- Updated blueprint state is replicated back to all connected players

The builder behaves like a collaborative editor, not a local client-owned construct screen.

## Boat Data Model

The boat should become a real block assembly immediately.

### `BoatBlueprint`

Recommended persistent fields:

- `blueprint_id`
- `version`
- `team_id` or current shared-boat key
- `build_bounds`
- `core_block_id`
- `blocks`
- `last_modified_at`
- `last_modified_by`

### `BlockRecord`

Each placed block should store:

- `block_id`
- `block_type`
- `cell`
- `rotation`
- `max_hp`
- `current_hp`
- `owner_peer_id` or last editor metadata
- stat contribution values or block-definition reference

### Initial Block Types

- `core`
  Required starting reference block for the first boat seed
- `hull`
  Main buoyancy and durability contributor
- `engine`
  Adds thrust and handling value
- `cargo`
  Adds cargo capacity at a weight cost
- `utility`
  Adds repair or brace-related benefits
- `structure`
  Cheap support or filler block with weaker stats

## Connectivity And Chunk Rules

Connectivity is a runtime concern, not a build-time constraint.

### In The Builder

- Players may place disconnected blocks or isolated mini-assemblies anywhere inside bounds
- The hangar should surface a `disconnected chunks detected` warning
- Launch remains allowed

### At Run Start

- The server computes adjacency connectivity from the saved blueprint
- One connected component becomes the `main active chunk`
- Recommended rule: use the chunk containing the core block if it still exists; otherwise use the largest connected chunk
- All other disconnected chunks spawn as loose pieces and sink immediately

### During The Run

- Blocks have HP and can be destroyed individually
- After each block destruction, the server recomputes connectivity
- Any component no longer attached to the main active chunk detaches
- Detached chunks become sinking debris objects and lose gameplay function

This delivers dramatic visible loss while keeping the controllable boat limited to one authoritative main chunk.

## Build-Mode UX

The builder should be collaborative, readable, and fast.

### Core Interaction Model

- Enter `build mode` from the hangar
- Show a bounded 3D build volume around the docked boat
- Each player gets:
  - selected block type
  - ghost preview
  - highlighted target cell
  - rotate, place, and remove controls
- All accepted edits appear live for everyone

### Co-op Editing Behavior

Recommended conflict model:

- no full-boat editing lock
- short-lived visual hover reservation per target cell
- first valid place action wins
- later conflicting edit is rejected with a short reason

Example rejection reasons:

- cell occupied
- out of bounds
- invalid block type
- blueprint changed; retry

### Hangar Feedback

The hangar should display:

- current block count
- aggregate boat stats
- `seaworthy` or `disconnected chunks detected`
- expected launch warnings for loose chunks
- current blueprint version

## Runtime Stat Derivation

The current extraction loop should remain in place but be driven by the new block-built boat.

### Derived Boat Stats

At run start and after block/chunk loss, the server should derive:

- `max_hull_integrity`
- `top_speed`
- `turn_response`
- `cargo_capacity`
- `repair_capacity`
- `brace_effectiveness`
- `buoyancy_margin`
- `weight_total`

### Initial Runtime Consequences

- losing hull or structure blocks reduces survivability and buoyancy
- losing engine blocks lowers speed and handling
- losing cargo blocks can reduce carrying capacity
- losing utility blocks weakens repair or brace-related performance
- if buoyancy margin falls below a minimum threshold, the main chunk sinks and the run fails

### Deliberate Simplification

The first version should not simulate:

- true per-block water displacement
- full roll and torque response
- per-fragment drivable rigid bodies

Instead, the system should:

- maintain one main active boat chunk
- recalculate aggregate stats whenever connected blocks change
- spawn detached chunks as server-owned sinking debris with simplified presentation

## Multiplayer Build Session Rules

The shared boat blueprint should be versioned and authoritative.

### Save Model

- one shared boat blueprint
- every accepted edit increments `version`
- clients render replicated state only
- run launch snapshots the current blueprint version into the run record

### Consistency Rules

- the run always uses the blueprint snapshot from launch time
- later hangar edits do not mutate an already running match
- out-of-date client edit requests should fail cleanly and require a retry against current version

## Failure Handling

- invalid place or remove requests are rejected server-side
- disconnected hangar builds show warnings but still allow launch
- disconnected chunks at run start sink immediately
- detached runtime chunks sink and stop contributing stats
- if the main chunk becomes non-seaworthy, the run fails
- if the core block is destroyed, the server reselects the main chunk according to the connectivity rule or fails the run if no viable chunk remains

## Recommended Milestone Breakdown

### Stage 1: Shared Builder Foundation

- boat blueprint schema
- block definitions
- bounded 3D build grid
- place, remove, rotate
- authoritative shared editing
- live replicated builder visuals

### Stage 2: Derived Stat Integration

- aggregate stat computation from block layout
- seaworthiness warnings in hangar
- run startup from shared blueprint instead of placeholder hull assumptions

### Stage 3: Per-Block Damage And Detachment

- block HP
- hazard-to-block damage mapping
- connectivity recompute after destruction
- detached chunk sinking
- live runtime stat recomputation

### Stage 4: Polish And Hardening

- improved build camera and controls
- conflict feedback
- save/load robustness
- clearer launch warnings
- better multiplayer session reliability

## Success Criteria

- Multiple players can co-edit one shared 3D block boat live in the hangar
- The blueprint persists and updates visibly for all editors
- Runs launch using the built boat rather than the placeholder hull
- Disconnected pre-launch chunks sink immediately at run start
- Runtime damage can destroy blocks and detach chunks
- Detached chunks sink and reduce boat capability without requiring full fragment physics
- The team can feel that boat shape and block choices materially affect extraction outcomes
