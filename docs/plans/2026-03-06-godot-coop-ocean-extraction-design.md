# Godot Co-op Ocean Extraction Design

Date: 2026-03-06

## Overview

This document captures the approved architecture direction for a desktop-first Godot implementation of a co-op ocean survival extraction game.

The game is a third-person 3D ocean extraction game where up to four players share one modular team boat in a server-authoritative run. Each run drops the crew into a seeded ocean instance filled with hazards, encounters, loot opportunities, and extraction pressure. Players return to a persistent hangar between runs for crafting, boat construction, upgrades, and progression.

The launch target is intentionally co-op only. The design preserves a future path to full per-block boat damage and richer simulation without requiring those systems to block the first playable release.

## Approved Product Decisions

- Platform target: desktop first
- Engine: Godot 4.x
- Multiplayer mode: co-op only
- Party size: up to 4 players
- Boat ownership in run: one shared team boat
- Boat construction timing: between runs only
- Runtime authority: dedicated authoritative server
- Launch boat damage model: ship-wide HP plus damage zones
- Future upgrade path: full per-block runtime damage and structural breakage

## Goals

- Deliver a tense co-op extraction loop built around shared-boat survival
- Preserve the fantasy of modular boat construction and long-term progression
- Support procedural replayability without requiring an unbounded seamless world
- Build an architecture that can evolve toward deeper damage and simulation later
- Keep progression secure and server-validated

## Non-Goals For V1

- PvP or PvPvE
- Live in-run boat rebuilding
- Fully seamless ocean world
- Full per-block destruction and buoyancy simulation
- Fully simulated water physics for every gameplay interaction

## High-Level Architecture

The game uses a two-process Godot model plus a persistence layer:

- Godot client
  Renders the world, handles input, camera, UI, VFX, audio, and local responsiveness
- Godot dedicated server
  Owns authoritative run simulation, including boat state, hazards, loot, encounters, extraction, and reward resolution
- Progression service
  Owns player accounts, currencies, materials, blueprint unlocks, saved boat builds, and hangar upgrades

The client sends player intent. The run server validates and resolves gameplay outcomes. The progression service persists only server-confirmed account changes.

## Scene And System Structure

Recommended top-level structure:

- `boot/`
  Bootstrap, config, account startup, service connection
- `hangar/`
  Boat building, inventory, crafting, blueprint unlocks, party assembly
- `run_client/`
  Gameplay HUD, camera, local input, replicated world view, water and weather presentation
- `run_server/`
  Headless run simulation scene for boat movement, hazards, loot, encounters, extraction, and scoring

Recommended networked runtime entities:

- `RunSession`
  Seed, timers, biome layout, escalation state, extraction rules
- `TeamBoat`
  Shared transform, velocity, crew occupancy, cargo, damage state, equipment modifiers
- `CrewMember`
  Player interaction state such as steering, grappling, bracing, repair, and reconnect handling
- `WorldChunk`
  Streamed runtime content region for islands, hazard lanes, wrecks, and pickups
- `Encounter`
  Server-owned event such as storms, monster attacks, debris fields, or puzzle sites
- `ExtractionPoint`
  Exit conditions, countdown state, and success/failure resolution

## Boat Data Model

The core design principle is to store boats in a per-block data format immediately, even though V1 gameplay damage is not yet fully per-block.

Recommended data structures:

- `BoatBuildDefinition`
  Saved hangar blueprint containing stable block IDs, grid coordinates, part type, material, orientation, and attachment metadata
- `BoatRuntimeState`
  Runtime instance that references the saved build and tracks current health, zone damage, cargo, modifiers, temporary effects, and repair state
- `BlockRecord`
  Stable per-block record for every placed part
- `DamageZone`
  Logical grouping of blocks such as bow, port, starboard, engine, and cargo

### V1 Runtime Damage

- Damage applies to overall ship HP and one or more damage zones
- Damaged zones can reduce speed, turning, brace efficiency, cargo safety, or hazard resistance
- Visual damage can be represented with broken materials, smoke, sparks, leaks, or disabled module visuals

### Future Upgrade Path

The boat system should expose damage APIs that can target:

- ship
- zone
- block

Even if V1 uses only ship and zone scopes, this preserves a direct migration path for:

- individual block durability
- flooding from local breaches
- structural detachment
- selective buoyancy loss
- module-level failures

This allows the project to build per-block in the hangar now, simulate per-zone in V1, and later increase fidelity without changing boat save formats.

## Multiplayer Model

The game uses a dedicated authoritative server for all run-critical systems.

### Client Responsibilities

- Input collection
- Camera and third-person follow behavior
- UI, effects, local animation blending, and audio
- Optional lightweight prediction for steering feel and interaction feedback

### Server Responsibilities

- Match creation and seeded run setup
- Boat transform and velocity authority
- Hazard simulation and encounter state
- Loot spawning and pickup validation
- Brace timing validation
- Grapple targeting, reel timing, and interruption resolution
- Extraction resolution
- End-of-run reward authorization

Clients never submit outcomes such as successful loot pickup, damage dealt, extraction success, or inventory mutations.

## Run Structure

Each run is a seeded, bounded ocean instance rather than an infinite seamless world.

Recommended region types:

- open water
- hazard corridor
- point of interest
- high-risk reward zone
- extraction zone

The server assembles these regions from a seed, difficulty tier, and biome mix. This creates variability while keeping pathing, performance, spawn logic, and encounter balancing manageable.

### Hazard Layers

To keep runs readable, hazards should be layered:

- Ambient hazards
  Waves, debris, fog, reefs
- Regional hazards
  Storm belts, whirlpool lanes, volcanic water, graveyards
- Encounters
  Monster attacks, special wreck events, puzzle sites, distress calls

### Difficulty Escalation

Danger should rise over time through:

- stronger wave and storm intensity
- increased encounter frequency
- harsher hazard penalties
- extraction urgency

This escalation is central to the extraction loop and should be deterministic from the server's perspective.

## Co-op Interaction Model

The design should emphasize shared stations and actions rather than fixed classes.

Recommended role interactions:

- Helm
  One player controls steering and throttle at a time
- Brace
  Any crew member can trigger a timed brace action before impact windows
- Grapple
  A crew member targets and reels loot or recovery items toward the boat
- Repair and Utility
  Crew members stabilize damage or clear status effects under pressure
- Navigation and Scan
  Crew members identify points of interest, hazards, or extraction timing

These should be flexible actions that any player can take, allowing crews to adapt moment to moment.

### Tension Rule

The most important moment-to-moment design rule is that the crew should be vulnerable while performing high-value actions. Grappling, repairs, puzzle interactions, and extraction should expose the boat to danger and force coordination.

## Progression And Persistence

The game should separate live run authority from long-term account state.

### Persistent Systems

- player account progression
- currencies and crafting materials
- blueprint unlocks
- saved boat builds
- hangar upgrades

### Reward Rules

- Gold and extract-only materials are granted only after server-confirmed successful extraction
- Blueprint discoveries unlock immediately on server-validated discovery, even if the run later fails
- Reward distribution should be automatic for V1 to reduce griefing and simplify group play

Each player owns their own account and progression, but the party chooses a shared team boat build before entering a run.

## Anti-Cheat And Trust Boundaries

The design should assume clients are untrusted.

### Never Trust The Client For

- loot grants
- extraction success
- damage results
- cargo mutations
- end-of-run summaries

### Server Validation Needed For

- grapple range and target availability
- brace timing windows
- repair interactions
- encounter completion
- extraction conditions
- progression write authorization

Only the run server may submit an authoritative completion result to the progression layer.

## Failure Handling

- Player disconnects should preserve the crew slot for a reconnect window
- If a disconnected player does not return, their avatar becomes inactive rather than disappearing immediately
- Boat destruction ends the run and removes extract-only rewards
- Successful extraction triggers one authoritative reward write
- If the server crashes before reward write completion, the run is unresolved rather than client-settled

## Godot Technology Recommendations

Recommended stack:

- Godot 4.x
- GDScript for most gameplay and orchestration
- C# or GDExtension only after profiling shows clear hotspots
- `ENetMultiplayerPeer` for gameplay networking
- `MultiplayerSpawner` for dynamic networked content
- `MultiplayerSynchronizer` only where selective replication is safe and useful
- Explicit custom gameplay authority for boat state, cargo, encounters, and progression writes

## Testing Strategy

The run simulation should be deterministic from seed plus ordered inputs wherever practical.

Recommended test layers:

- simulation tests
  Boat stat derivation, damage zone effects, loot rules, encounter generation, extraction resolution
- network tests
  Join, leave, reconnect, latency, duplicate RPC protection, interaction conflicts
- content tests
  Region validity, encounter placement, extraction reachability, loot spawn sanity
- soak tests
  Long-running headless server matches to detect desyncs, leaks, and runaway state growth
- playtest scenarios
  Storm navigation, brace timing, grappling under pressure, partial repair recovery, last-second extraction

## Phased Roadmap

### Phase 1: Foundation Prototype

- Dedicated server connection
- Shared boat movement
- One simple ocean region type
- Basic third-person camera
- Crew presence on deck
- One extraction flow

### Phase 2: Core Loop Vertical Slice

- Up to four players
- Shared boat session flow
- Grappling
- Brace mechanic
- Cargo
- One or two hazard types
- Run success and failure

### Phase 3: Progression Alpha

- Hangar flow
- Boat save and load
- Materials and gold
- Blueprint unlocks
- Zone-based damage
- Upgrade choices
- Server-authoritative persistence

### Phase 4: Content Alpha

- More biomes
- More encounters
- Buff and curse loot
- Passive hazard resistance equipment
- Better role interactions
- Improved events and AI

### Phase 5: Hardening And Expansion

- Reconnect polish
- Performance tuning
- Admin and analytics tooling
- Economy balancing
- Selective migration toward block-level runtime damage on high-value parts

## Key Recommendation

Do not block the first playable version on full per-block destruction. Build the saved boat format and runtime APIs with block identity now, but prove the core fun with shared-boat co-op extraction, strong hazard pressure, and coordinated crew actions first.

## Open Questions

- What progression service stack should back account and inventory persistence
- Whether account services should live inside Godot tooling first or as a separate backend
- Which boat stations and interactions deserve dedicated physical deck positions in the first playable build
- How much direct on-foot deck movement players need during a run versus station-based interaction shortcuts
