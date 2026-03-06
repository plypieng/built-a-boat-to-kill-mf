# Godot Co-op Ocean Extraction Implementation Plan

Date: 2026-03-06
Depends on: `docs/plans/2026-03-06-godot-coop-ocean-extraction-design.md`

## Objective

Build a desktop-first Godot prototype for a co-op ocean extraction game with:

- up to 4 players
- one shared team boat
- dedicated authoritative server
- seeded instanced runs
- between-run boat construction
- ship-wide HP plus damage zones
- future-compatible per-block boat data

## Delivery Strategy

The project should move through narrow, playable milestones. Each milestone must end with something testable by a small team, not just infrastructure.

## Milestone 0: Project Foundation

### Goals

- Create a runnable Godot client project
- Create a headless server project mode or dedicated server entry scene
- Establish repository structure and conventions
- Prove a client can connect to a local dedicated server

### Tasks

- Initialize Godot 4.x project
- Add client boot scene and server boot scene
- Define folders for `autoload/`, `scenes/`, `systems/`, `data/`, `net/`, and `ui/`
- Add environment config for local development
- Add a basic multiplayer connection flow using `ENetMultiplayerPeer`
- Add developer logging and build/run scripts
- Add deterministic seed plumbing for server-created runs

### Exit Criteria

- One local client connects to a local headless server
- Server can create a dummy run session with a known seed
- Repo includes clear boot path documentation

## Milestone 1: Shared Boat Movement Prototype

### Goals

- Get one shared boat moving in a simple ocean arena
- Establish authoritative boat transform and replication
- Support multiple players joining the same crew

### Tasks

- Implement `RunSession` server authority object
- Implement `TeamBoat` authoritative movement model
- Add third-person boat follow camera
- Add player deck presence or placeholder crew representation
- Add driver control ownership transfer
- Replicate boat transform, velocity, and control state
- Implement reconnect window and inactive-player fallback

### Exit Criteria

- Up to 4 clients can join one run
- One player can drive while others observe the same authoritative boat state
- Disconnect and reconnect work without corrupting the run

## Milestone 2: Vertical Slice Core Loop

### Goals

- Deliver the first tense extraction loop
- Validate shared actions under pressure

### Tasks

- Add one seeded region layout generator
- Add one extraction zone
- Add one hazard type such as storm impacts or debris collisions
- Add brace action with timed mitigation window
- Add grapple interaction for floating loot
- Add shared cargo inventory with limited capacity
- Add run fail state on boat destruction
- Add successful extraction resolution

### Exit Criteria

- A 2-4 player crew can launch, navigate, gather loot, survive hazards, and extract
- Brace and grapple are both server-validated
- Failure removes extract-only rewards from the run

## Milestone 3: Hangar And Persistent Progression

### Goals

- Connect runs to long-term progression
- Establish saved boat build and account data flow

### Tasks

- Add player account/profile storage abstraction
- Add persistent currencies and materials
- Add automatic reward distribution after extraction
- Add blueprint unlock tracking
- Implement hangar scene
- Implement boat save/load using `BoatBuildDefinition`
- Add basic crafting and one or two upgrade paths
- Add immediate blueprint unlock behavior on discovery

### Exit Criteria

- Players can return from a run and see persistent rewards in the hangar
- Boat builds save and load cleanly
- Blueprint unlock rules match the approved design

## Milestone 4: Damage Zones And Boat Build Stats

### Goals

- Make boat building matter in-run without requiring full per-block destruction

### Tasks

- Implement `BlockRecord` data in build definitions
- Implement derived ship stats from block composition
- Define initial damage zones such as bow, port, starboard, engine, and cargo
- Map hazard impacts and encounter effects to ship and zone damage
- Add zone-driven gameplay penalties
- Add repair interactions for zone stabilization
- Add visual feedback for damaged zones

### Exit Criteria

- Different boat builds produce different runtime handling or survivability
- Damage zones affect gameplay in visible, understandable ways
- Internal data remains compatible with future block-level damage

## Milestone 5: Procedural Content And Roles Expansion

### Goals

- Improve replayability and co-op depth

### Tasks

- Add additional region templates
- Add at least two more hazard families
- Add one encounter type such as a monster event or wreck puzzle
- Add navigation or scan utility role
- Add passive equipment slot system for resistances or utility bonuses
- Add buff and curse loot items
- Improve extraction event pressure

### Exit Criteria

- Runs feel meaningfully different across seeds
- Crews benefit from dividing responsibilities
- Risk versus reward choices are present throughout a run

## Milestone 6: Performance, Stability, And Operations

### Goals

- Prepare the prototype for wider testing

### Tasks

- Add headless soak-test harness for repeated server-run simulations
- Add network resilience tests for delay, loss, and reconnect
- Profile boat replication and world chunk spawning
- Add chunk streaming and content culling where needed
- Add server admin commands and telemetry hooks
- Add crash diagnostics and unresolved-run handling

### Exit Criteria

- Dedicated server remains stable over repeated match cycles
- Run completion and failure handling are robust
- Performance is acceptable for internal or closed-alpha playtests

## Cross-Cutting Technical Tasks

These should be worked continuously instead of left until the end.

### Networking

- Standardize client intent RPCs
- Build authority checks into every interaction system
- Keep replication payloads explicit and measurable

### Determinism

- Ensure run generation is driven by server seed plus config version
- Keep combat, hazard, and loot resolution reproducible enough for testing

### Tooling

- Add local scripts to run client and server together
- Add debug overlays for authority state, latency, and damage zones
- Add content validation tools for region generation

### Data Contracts

- Freeze early schemas for:
  - `BoatBuildDefinition`
  - `BoatRuntimeState`
  - `RunSession`
  - reward write payloads
  - blueprint unlock records

## Suggested Initial Repo Layout

```text
autoload/
docs/plans/
scenes/boot/
scenes/hangar/
scenes/run_client/
scenes/run_server/
systems/boat/
systems/run/
systems/hazards/
systems/loot/
systems/progression/
systems/worldgen/
net/
ui/
data/
tests/
tools/
```

## Recommended First Sprint

The first sprint should focus only on proving the multiplayer foundation.

### Sprint Scope

- Godot project bootstrap
- headless server entry point
- local connect flow
- one shared boat actor
- third-person follow camera
- up to 4 clients in one run
- authoritative steering replication

### Sprint Success Test

Four local clients can connect to a local server and watch one player drive the same shared boat around a simple ocean arena with stable synchronization.

## Main Risks

- Boat movement feels poor if authority and responsiveness are not balanced carefully
- Progression complexity can sprawl if persistence contracts are not defined early
- Procedural content can become costly if region templates are not bounded
- Future block-level damage can still become expensive if current zone systems leak assumptions into all gameplay code

## Risk Mitigations

- Keep boat control prediction minimal and measurable
- Separate progression writes from run simulation early
- Use bounded region templates instead of infinite world generation
- Preserve `ship`, `zone`, and `block` damage scopes in APIs from the start

## Definition Of Done For The First Public Prototype

- Players can form a party and enter a seeded run
- Up to 4 players share one boat
- The crew can steer, brace, grapple loot, survive hazards, and extract
- The run has real loss on failure and persistent reward on success
- Boats are built between runs and affect runtime performance
- The server remains authoritative for all outcome-critical systems
