# Boat Builder, Propulsion, And Station Implementation Plan

Date: 2026-03-09

## Overview

This document translates the approved design into a production-facing implementation plan.

It assumes the current prototype already has:

- a shared block-built boat
- claimable helm and grapple stations
- mobile brace and repair actions
- crew vitals
- seeded hazards, salvage, rescue, and extraction

The purpose of this plan is to move the prototype from `boat as stat bundle` to `boat as operated machine`.

## Phase 0: Foundations Audit

Before adding new player-facing systems, verify the current foundation.

### Goals

- confirm which boat stats are already derived from block definitions
- confirm which run systems can already react to lost blocks and chunk loss
- confirm current station claim, release, and range behavior
- confirm HUD capacity for propulsion and machine state readouts

### Deliverables

- runtime stat source inventory
- current station system inventory
- list of code paths where helm directly manipulates boat movement

## Phase 1: Intent-Driven Helm

This is the biggest architectural shift.

### Product Goal

Replace direct boat motion input from helm with an intent layer:

- heading intent
- rudder
- speed order

### Runtime Goal

The shared boat should move because a propulsion profile converts helm orders into thrust.

### Deliverables

- helm speed-order state
- propulsion efficiency state
- rudder intent state
- actual thrust separate from commanded speed

### Acceptance Criteria

- helm can no longer directly set acceleration
- the boat still feels responsive
- existing extraction loop remains playable with a placeholder propulsion package

## Phase 2: Propulsion State Framework

Add a server-authoritative propulsion layer to the run state.

### Required Runtime Fields

- `propulsion_family`
- `speed_order`
- `rudder_input`
- `actual_thrust`
- `propulsion_efficiency`
- `automation_floor`
- `manual_ceiling`
- `burst_ceiling`
- `fault_state`
- `fault_severity`
- `propulsion_heat`
- `propulsion_pressure`
- `propulsion_trim`
- `propulsion_sync`

Not every family needs every field, but one shared state surface keeps the HUD and netcode simpler.

### Acceptance Criteria

- propulsion state replicates cleanly
- missing-family fields degrade gracefully
- the HUD can show useful propulsion data without family-specific hacks everywhere

## Phase 3: Propulsion Family Slice 1

Ship two propulsion families first:

- `Raft Paddles`
- `Steam Tug Drive`

This pairing gives one labor-heavy low-tech system and one engineering-heavy machine system.

### Raft Paddles

Deliver:

- port and starboard support stations or burst stations
- stamina-driven manual assist
- asymmetry when one side is under-crewed

### Steam Tug

Deliver:

- engineer console
- pressure or heat management
- vent burst interaction
- spool-up behavior

### Acceptance Criteria

- both families are playable solo
- both families feel clearly different in motion and crew labor
- both families create at least one recoverable fault state

## Phase 4: Builder UI Report Upgrade

The builder must explain the machine before launch.

### Required UI Additions

- float margin
- top speed
- acceleration
- turn authority
- storm stability
- crew safety
- repair coverage
- propulsion health
- workload
- recommended crew
- risk warnings

### Required Overlays

- pathing
- recovery access
- repair coverage
- propulsion exposure
- damage redundancy

### Acceptance Criteria

- players can understand why a build is risky before launching
- the same build report updates correctly when blocks are added or removed

## Phase 5: Station System Expansion

Expand stations without overcomplicating the deck.

### New Station Categories

- persistent propulsion stations
- burst propulsion support stations
- improved recovery modules
- support module influence zones

### Rules To Preserve

- brace stays mobile
- rally stays mobile
- recover stays contextual
- repair stays primarily local, with module-supported efficiency

### Acceptance Criteria

- role identity becomes clearer
- deck improvisation still exists
- the player does not need to learn a new button map for each propulsion family

## Phase 6: Run Pressure Integration

Connect the machine model to the existing run.

### Required Integrations

- collisions affect propulsion health where appropriate
- lost hull and support pieces change safety and handling
- lost propulsion pieces change thrust and response
- support module loss changes repair, brace, or recovery behavior
- extraction respects damaged propulsion state

### Acceptance Criteria

- damage changes how the boat behaves, not only its HP
- crises force role swaps and movement
- specialist boats experience real strengths and real weaknesses

## Phase 7: Propulsion Family Slice 2

Once the first two families are solid, add:

- `Fore Sail Rig`
- `Twin Screw Engine`

These provide the next two identity extremes:

- route-smart environmental propulsion
- high-precision fragile propulsion

## Phase 8: Progression And Unlock Integration

Once families and builder readouts are stable, wire progression.

### Deliverables

- unlock tables
- propulsion family gating
- support module unlocks
- part-library filtering by tier
- reward economy hookups

### Acceptance Criteria

- players unlock new choices without invalidating old ones
- there is no mandatory propulsion line

## Technical Workstreams

### Runtime Systems

- boat propulsion simulator
- station occupancy and burst interaction layer
- support influence zone derivation
- machine fault generation and recovery

### Builder Systems

- per-module tags for hull, support, propulsion, recovery, and station families
- derived metric calculator
- warning generator
- overlay generator

### HUD Systems

- propulsion panel
- family-specific station prompts
- fault callouts
- clearer order-versus-actual movement readouts

### Content Authoring

- block definitions with role metadata
- propulsion package definitions
- unlock metadata
- archetype presets for testing

## Suggested Milestones

### Milestone A

- intent-driven helm
- propulsion state framework
- placeholder thrust conversion

### Milestone B

- Raft Paddles
- Steam Tug
- propulsion HUD

### Milestone C

- builder report and overlays
- support influence zones
- better station UI

### Milestone D

- sail and twin-engine families
- deeper fault states
- progression hooks

### Milestone E

- hybrid propulsion
- archetype presets
- balance pass and playtest telemetry

## Testing Plan

### Functional

- every legal blueprint still launches
- every required station remains reachable after edits
- propulsion family state replicates correctly in multiplayer
- losing key modules changes derived stats correctly

### Playtest

- solo play with each propulsion family
- duo and trio role clarity
- specialist archetype validation
- crisis readability under damage

### Balance

- no one propulsion family dominates all seeds
- workload meaningfully predicts preferred crew count
- builder warnings correlate with actual failure patterns

## Risks

- making propulsion feel sluggish after removing direct helm force
- overcomplicating station interactions
- introducing unreadable HUD clutter
- allowing too many family-specific exceptions
- creating builder metrics that players cannot trust

## Mitigations

- keep one shared control grammar
- keep a small readable metric suite
- ship propulsion families in pairs for comparison
- preserve automation floor
- expose plain-language warnings alongside numbers

## Decision Log

- Decision: phase the system through two propulsion families first
  Alternative: ship all four families together
  Resolution: rejected because balancing and onboarding would be too noisy
- Decision: upgrade the builder report before deep progression
  Alternative: add more content first
  Resolution: rejected because players need interpretable feedback before the sandbox expands
- Decision: preserve mobile deck actions
  Alternative: broaden seated interactions aggressively
  Resolution: rejected because it would make the prototype harder to read and balance

## Success Criteria

This implementation plan is successful when:

- the helm no longer feels like a direct vehicle controller
- at least two propulsion families feel clearly distinct and shippable
- the builder explains the boat well enough that players can predict failure patterns
- damage changes motion, crew flow, and risk in visible ways
- the system is robust enough to support future sail, engine, and hybrid content without a rewrite
