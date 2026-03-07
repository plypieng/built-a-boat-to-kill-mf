# Runtime Block Damage Design

Date: 2026-03-08

## Overview

This document captures the approved design for Milestone B: making the built boat materially matter during the extraction run.

The milestone replaces the placeholder run-time hull presentation with the actual launched block boat. The authoritative server tracks per-block HP, applies localized damage to a small cluster of nearby blocks, recomputes chunk connectivity after destruction, and detaches newly disconnected chunks as sinking debris. Detached chunks immediately stop contributing cargo, utility, thrust, brace, and survivability value.

This milestone keeps the run model deterministic and multiplayer-safe by preserving one controllable main chunk and treating all detached chunks as simplified sinking debris rather than full drivable boats.

## Approved Product Decisions

- Launch-time disconnected chunks should sink immediately
- The first per-block damage pass should hit a small local cluster, not only one block
- Detached chunks should matter immediately by removing their gameplay contribution as soon as they separate

## Goals

- Render the actual built boat in the run
- Make impacts damage real blocks instead of only an abstract hull pool
- Allow chunk detachment and visible sinking during extraction
- Make chunk loss immediately affect speed, cargo, repair, brace, and survivability
- Keep the simulation authoritative and deterministic for co-op multiplayer

## Non-Goals For This Milestone

- Fully drivable detached chunks
- Real per-block fluid displacement simulation
- Reattachment or rebuilding during a run
- Fully physical fragment-to-fragment collision simulation
- Advanced art polish for broken pieces

## Runtime Architecture

Milestone B introduces a block-first runtime state model.

### Core Runtime State

- `BoatRuntimeSnapshot`
  The blueprint snapshot taken at launch time
- `RuntimeBlockState`
  One record per launched block, including:
  - block id
  - block type
  - cell
  - rotation
  - current HP
  - max HP
  - destroyed flag
  - chunk id
- `RuntimeChunkState`
  One record per connected component, including:
  - chunk id
  - block ids
  - main-chunk flag
  - detached flag
  - sinking flag
  - derived chunk stats
- `SinkingDebrisState`
  Simplified detached chunk presentation records replicated to clients

### Authority Model

- The server owns launch snapshot creation
- The server computes initial chunk connectivity
- The server selects the main active chunk
- The server applies block damage
- The server recomputes connectivity after block destruction
- The server detaches and sinks non-main chunks
- Clients render the replicated result

## Main Chunk Selection

Selection must be deterministic.

### Rule

- Prefer the chunk containing the core block
- If the core block no longer exists, pick the largest remaining viable chunk
- If no viable chunk remains, fail the run

At run start:

- The main chunk becomes the controllable team boat
- All pre-disconnected chunks become loose sinking debris immediately
- Derived boat stats come only from the main chunk

During the run:

- Newly disconnected chunks detach and become sinking debris
- Their stat contribution is removed immediately

## Damage Mapping

The first damage pass should be local and readable.

### Damage Flow

- Determine impact point in boat-local space
- Find the nearest launched block
- Select a small nearby cluster around that point
- Apply weighted damage:
  - primary hit block receives full damage
  - nearby blocks receive reduced splash damage

### Recommended First Pass

- cluster size: roughly 3 to 5 blocks
- nearest block: 100 percent
- adjacent blocks: 35 to 60 percent depending on distance
- brace reduces total event damage before distribution

This makes impacts feel spatial without requiring full force propagation.

## Connectivity And Detachment

Connectivity uses 6-direction grid adjacency.

### After Block Destruction

- Destroyed blocks are removed from the live connectivity graph
- The server recomputes connected components
- Any component no longer attached to the main chunk detaches
- Detached chunks become sinking debris records

### Detached Chunk Behavior

- Detached chunks immediately stop contributing:
  - thrust
  - cargo capacity
  - repair capacity
  - brace value
  - hull and buoyancy value
- Detached chunks drift downward and away
- Detached chunks do not reattach in this milestone
- Detached chunks are visual/gameplay remnants, not controllable physics vessels

## Gameplay Consequences

Chunk loss must matter the instant it happens.

### Immediate Effects

- losing an engine chunk lowers speed and handling right away
- losing a cargo chunk lowers cargo capacity right away
- losing a utility chunk lowers repair or brace value right away
- losing enough hull or buoyancy can sink the main chunk and fail the run

### Cargo Rule

- if current cargo exceeds the new cargo capacity after chunk loss
- the overflow becomes `cargo_lost_in_sea` immediately
- HUD and result state should surface that loss clearly

### Repair Supplies Rule

- current remaining repair supplies clamp down to the new max if utility support is lost

## Rendering Strategy

The run should render the built boat directly from the launched block snapshot.

### Client Rendering Model

- clients reconstruct block visuals locally from replicated block data
- server replicates state, not raw meshes

### Visual Rules

- replace the placeholder hull with block-based visuals
- main chunk stays under the shared boat root
- destroyed blocks disappear or switch to a broken state
- detached chunks render under separate sinking roots
- pre-disconnected chunks appear as sinking debris at launch

### First-Pass Visual Style

- simple box meshes per block type
- optional facing marker per block
- damage flash or tint on recently hit blocks
- detached chunks darken or desaturate for readability

## Replication Strategy

Use explicit event/state replication.

### Replicated Payloads

- launch snapshot
- runtime block state updates
- chunk assignment and detachment updates
- sinking debris state
- derived main-boat stat updates

Detached chunks should be represented as simplified replicated debris, not fully simulated boats.

## Failure Handling

- if the main chunk becomes non-viable, the run fails
- if the core block is lost but another viable chunk exists, promote the largest viable chunk
- if no viable chunk exists, fail the run
- detached chunks never reattach in this milestone
- cargo overflow from chunk loss is discarded immediately

## HUD And Result Changes

### HUD Additions

- main chunk block count
- current cargo capacity
- cargo lost to chunk detachment
- short chunk-loss event messages
- optional loss callouts such as:
  - engine lost
  - cargo bay lost
  - utility lost

### Result Additions

- launched blueprint version
- blocks destroyed
- chunks lost
- cargo lost to the sea

## Recommended Milestone Breakdown

### Stage 1: Run-Time Block Rendering

- render the actual launched boat in-run
- sink disconnected launch chunks immediately

### Stage 2: Per-Block Runtime State

- add block HP
- add chunk ids
- add destroyed flags
- add chunk records

### Stage 3: Localized Damage

- map impacts to a nearby block cluster
- destroy blocks at zero HP

### Stage 4: Connectivity And Detachment

- recompute chunks after destruction
- detach non-main chunks
- spawn sinking debris
- remove stat contribution immediately

### Stage 5: UX And Verification

- update HUD and result screen
- validate headless and manual desktop flows

## Exit Criteria

- the run renders the actual built boat
- disconnected launch chunks sink immediately
- impacts can destroy blocks
- detached chunks sink and reduce boat capability immediately
- cargo overflow can be lost to chunk detachment
- the run remains stable in multiplayer

## Recommendation

Stop at meaningful chunk loss for this milestone. One controllable main chunk plus simplified sinking debris gives the game the right construction-and-destruction fantasy without exploding multiplayer complexity.
