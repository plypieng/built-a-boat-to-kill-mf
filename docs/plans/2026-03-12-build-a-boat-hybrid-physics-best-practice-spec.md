# Build-A-Boat Hybrid Physics Best Practice Spec

Date: 2026-03-12

## Overview

This document defines the recommended physics and player-interaction model for a build-a-boat game.

It is not a realism target.
It is a best-practice gameplay target for games where:

- players build boats from modular blocks
- boats must feel stable in multiplayer
- players walk, jump, fall overboard, swim, and recover
- boat layout should matter without turning the game into rigidbody chaos

The approved direction is:

- simulate the boat as one vessel during normal play
- keep deck movement physically real
- treat water as a tuned traversal state
- make reboarding forgiving and readable
- only split into separate physics chunks when the build actually breaks apart

## Design Principles

### 1. Keep The Deck Real

If players can stand on it, it should be collidable and trustworthy.

- deck blocks should have runtime collision
- on-boat movement should use real character floor detection
- jump and gravity should work normally on deck

Players will forgive stylized water.
They will not forgive an unreliable deck.

### 2. Fake The Water Aggressively

Water should be tuned for feel, not simulated as full fluid dynamics.

- use sampled wave height and authored buoyancy response
- use swim/tread controllers for characters
- use explicit state transitions for splash entry and reboarding

Water is a traversal and danger layer, not a rigidbody sandbox.

### 3. Simulate The Boat As A Vessel, Not A Pile Of Parts

The launched boat should usually behave as one runtime vessel.

- derive vessel stats from the built blueprint
- use those stats to influence thrust, drag, trim, heel, and stability
- do not run all blocks as independent live rigidbodies during normal sailing

This is the core stability rule for the genre.

### 4. Transitions Matter More Than Raw Physics

The hardest part of this system is not buoyancy.
It is the boundary between:

- deck
- falling
- water entry
- surface tread
- swim
- reboard

If those transitions feel abrupt or inconsistent, the whole game feels fake even when the underlying math is correct.

### 5. Recovery Must Be Redundant

Players should have more than one valid way back onto the boat.

- ladder recovery
- stern line recovery
- direct hull-edge reboard when deck is reachable
- damaged-boat fallback paths

If a boat breaks and recovery becomes impossible, players read that as a system failure unless it was clearly intentional.

## Recommended Runtime Model

## Boat Layer

The boat runtime should be authoritative and vessel-level.

Responsibilities:

- buoyancy response
- thrust and drag
- trim and roll bias
- speed limits
- impact handling
- structural detachment triggers

Inputs:

- blueprint block layout
- block mass/buoyancy/thrust/durability definitions
- wave sampling
- control input
- damage state

Outputs:

- boat position and orientation
- derived vessel metrics
- runtime collidable deck geometry
- detached chunk events

## Structure Layer

Blueprint blocks are authored data first.

Each block should contribute to:

- occupied volume
- mass
- buoyancy
- durability
- walkable deck support
- recovery access
- connectivity groups

Detached chunks should only become separate drifting or sinking objects after connectivity or destruction rules say they should.

## Character Layer

Character movement should use three main gameplay states:

### `deck`

- `CharacterBody3D`
- real collision against runtime boat geometry
- normal jump and gravity
- station and deck interactions

### `water_entry`

- short transition after leaving valid boat support
- preserve momentum from deck and boat motion
- apply splashdown damping near the surface
- do not snap directly from deck to swim

### `overboard`

- swim and surface-tread controller
- camera-relative movement
- drag and acceleration curves
- buoyant presentation
- recovery and reboard rules

This state split is a best practice because it keeps deck feel solid while letting water feel authored and consistent.

## Recovery Layer

Best practice is to treat recovery as a validated interaction, not raw collision improvisation.

Recovery priority should be:

1. direct hull-edge reboard if reachable deck is nearby
2. ladder or stern-line recovery point
3. assisted recovery or special fallback rules

This gives players freedom without requiring physically perfect swimming collision against every moving hull face.

## Multiplayer Rules

The recommended authority split is:

- server authoritative for boat state
- server authoritative for avatar gameplay mode
- client responsive for local movement feel and camera
- remote avatars can stay presentation-driven until higher fidelity is necessary

Do not attempt full deterministic networked physics for all blocks and all players unless the game absolutely depends on it.

For this genre, that cost is usually not worth it.

## Best-Practice Behavior Rules

### Deck Rules

- the player should never clip through intact deck blocks
- deck collision should match visible runtime geometry
- jumping on deck should feel like ordinary third-person character movement

### Fall-Off Rules

- leaving the hull should feel continuous
- stepping off should not cause a visible hover or snap
- if the player is still plausibly able to land back on the deck, keep deck collision briefly
- once the player clearly clears the hull, switch to water-entry

### Swim Rules

- surface tread should be the default resting state
- swim input should be camera-relative
- movement should feel heavier than deck motion
- speed and turn response should be readable and tunable

### Reboard Rules

- nearby low deck edges should be boardable
- ladders should remain the most readable recovery aid
- recovery input should work consistently across all valid reboard targets
- broken boats should still permit recovery if any reachable deck remains

## Anti-Patterns To Avoid

- rigidbody-per-block sailing as the default runtime
- deck locomotion that depends only on invisible snap points
- instant deck-to-swim state changes with no transitional feel
- overboard states that disable all meaningful hull interaction
- exact-point-only recovery requirements
- systems where collision behavior changes unpredictably near the hull

These are common sources of “it feels wrong” feedback even when the implementation is technically correct.

## Project Mapping

For this project, the intended system boundaries are:

- `autoload/network_runtime.gd`
  Owns vessel stats, runtime block data, recovery validation, avatar gameplay modes, and server authority.
- `scenes/run_client/run_client.gd`
  Owns local deck controller, water-entry feel, overboard presentation, camera behavior, and client responsiveness.
- `scenes/shared/avatar/player_controller_3d.gd`
  Owns the physical character body and collision capsule.
- `scenes/shared/avatar/player_avatar_visual.gd`
  Owns presentation, locomotion blending, and visual fit to the collision body.

Contributors should preserve this split.

Do not move boat simulation into the avatar controller.
Do not move avatar feel logic into the server runtime unless it must be authoritative.

## Current Project Direction

The current project is already aligned with the best-practice model in these ways:

- runtime boat blocks provide collidable deck geometry
- the local deck avatar uses real `CharacterBody3D` movement
- overboard now uses explicit transition states instead of a pure snap
- direct hull-edge reboard is allowed in addition to ladder recovery
- detached chunks remain separate from normal main-vessel walking rules

The remaining work is mainly in feel polish, not a foundation rewrite.

## Recommended Next Steps

### Priority 1

- add dedicated tread and swim animation states
- improve overboard camera roll and splash feedback
- make reboard placement and short pull-up presentation more readable

### Priority 2

- add more robust damaged-boat fallback recovery logic
- add hull-side helper volumes for obvious climbable edges
- improve water audio and wake feedback near the player

### Priority 3

- evaluate whether remote avatars need higher-fidelity water presentation
- add richer chunk interaction only if gameplay requires it

## Team Rule

If the team needs one sentence to align on this system, it should be:

`Simulate the boat as a vessel, simulate the player as a character, and simulate water as a tuned traversal state.`

That is the recommended best-practice foundation for this game type.
