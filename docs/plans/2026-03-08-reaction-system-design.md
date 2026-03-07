# Reaction System Design

Date: 2026-03-08

## Overview

This document captures the approved design for the first shared reaction-system milestone. The goal is to make impacts feel physical and funny across both the social hangar builder and the extraction run without introducing true ragdolls yet.

The system should cover three early cases:

- hard player-to-player bumps in the hangar
- strong unbraced impacts during runs
- future hooked or harpoon-style pull effects

The first version should briefly affect control, apply knockback, and visibly sell the hit with a short stumble or dragged state. It should recover quickly and remain authoritative in multiplayer.

## Approved Product Decisions

- Scope: both `hangar` and `run`
- Control impact: reactions should briefly affect control, not just visuals
- Hangar bump source: include player-to-player bumping
- Hangar bump threshold: only trigger on hard collisions
- Harpoon support: use a hooked or dragged reaction state, not true ragdolls
- Brace purpose: brace should reduce reaction severity during runs
- First implementation model: state-driven reaction system

## Goals

- Make collisions and pulls feel physical before ragdolls exist
- Reinforce brace as meaningful gameplay, not cosmetic feedback
- Add comedic social collisions to the hangar without making normal movement miserable
- Keep the system authoritative and reusable across both hangar and run
- Create a clean upgrade path for later ragdoll-heavy events

## Non-Goals For This Milestone

- True skeletal ragdolls
- Long stun locks or helpless states
- Full-body physics pushing between players
- Monster grabs or full harpoon gameplay content
- Chain-reaction chaos from tiny nudges
- Animation polish beyond what is needed to sell the state clearly

## Experience Goal

The desired feel is:

- small hard bumps in the hangar cause a quick, funny shove and stumble
- unbraced run impacts clearly knock the crew around and disrupt actions
- hooked pulls feel dangerous because movement is briefly overridden
- brace noticeably reduces both damage and how badly the crew gets thrown

The reactions should be:

- readable
- short
- disruptive enough to matter
- fast to recover from

They should not become constant micro-interruptions during ordinary movement.

## Reaction Types

### Bump Reaction

Triggered by hard avatar-to-avatar collisions in the hangar or on the boat.

Behavior:

- short knockback impulse
- brief stumble duration
- partial movement suppression
- quick recovery

This is the main social-comedy layer.

### Impact Reaction

Triggered by strong collisions, hazards, or unbraced salvage backlash during runs.

Behavior:

- stronger knockback than a bump
- short control loss or movement impairment
- optional station interruption on heavier hits
- camera jolt and visible lean or tilt

This is the main tension layer that supports brace gameplay.

### Hooked Or Pulled Reaction

Triggered by future harpoon or drag effects.

Behavior:

- forced movement toward a pull vector or anchor point
- reduced or overridden movement control during the pull
- stronger dragged posture than a normal stumble
- brief recovery when the pull ends

This uses the same reaction-state system instead of requiring ragdolls.

## Reaction State Model

The server should own a lightweight reaction state per affected player.

Recommended fields:

- `reaction_type`
  - `bump`
  - `impact`
  - `hooked`
- `reaction_strength`
- `reaction_timer`
- `recovery_timer`
- `knockback_velocity`
- `pull_target` or `pull_direction`
- `source_peer_id` or source event id
- `brace_applied`

This model is shared across the hangar and the run, while the movement controllers that consume it remain scene-specific.

## Architecture

### Shared Authority

The authoritative side owns:

- when a reaction starts
- how strong it is
- how long it lasts
- the resulting movement impulse or pull
- whether brace mitigation reduced it

Clients should render the result rather than inventing it.

### Hangar Integration

Each hangar avatar gets a reaction state.

The server detects:

- hard player bumps
- future environment shoves if needed

The hangar client applies:

- knockback movement
- brief stumble interruption
- visual lean or tilt
- recovery back into normal builder control

### Run Integration

Each run crew member also gets a reaction state.

The run server triggers reactions from:

- unbraced impacts
- strong hazards
- salvage backlash
- future hook or pull mechanics

The run client applies:

- knockback or drag presentation
- brief action interruption
- optional forced station release on heavier impacts
- stronger camera feedback than the hangar version

## Trigger Rules

### Hard Collision Thresholds

Hangar bumps should trigger only when collision speed is high enough, such as:

- sprinting into another player
- landing on another player
- colliding while already reacting

Normal walking contact should not trigger a reaction.

### Run Impact Triggers

Run reactions should trigger from major boat events rather than every small movement update. Early sources:

- collision impacts
- unbraced salvage backlash
- future monster or harpoon interactions

### Brace Mitigation

Brace should reduce:

- knockback strength
- stumble or recovery duration
- chance of losing station control

This keeps brace aligned with the game’s core impact fantasy.

## Control Effects

Recommended first-pass control consequences:

- `light bump`
  - movement damped briefly
  - actions feel interrupted but recover almost immediately
- `heavy impact`
  - short input suppression
  - stronger shove
  - possible station release
- `hooked`
  - movement partially or fully overridden during the pull
  - short recovery afterward

These windows should stay short enough that the game remains funny and tense rather than frustrating.

## Presentation

The first milestone should avoid full animation complexity and instead use simple readable presentation:

- body lean
- quick tilt or flop pose
- knockback slide
- camera jolt for local impacts
- clear recovery back to neutral

The same reaction state can later drive:

- better character animation
- hybrid ragdoll finishes
- monster grabs
- harsher catastrophic impacts

## Risks

### Over-Triggering

If hangar bumps trigger on normal walking contact, the builder becomes annoying instead of funny.

### Control Friction

If control interruption lasts too long, reactions will feel unfair rather than exciting.

### Multiplayer Divergence

If the server and client disagree on when a reaction happened, the result will feel sloppy immediately.

### Station Frustration

If run reactions constantly boot players off stations, the co-op loop will become noisy and frustrating.

## Implementation Order

1. Add shared reaction data and replication in `NetworkRuntime`
2. Add hangar hard-bump detection and reaction presentation
3. Add run impact-triggered reaction presentation and brief action interruption
4. Add hooked or pulled state support using the same reaction model
5. Tune thresholds and recovery so the system stays funny and readable

## Testing Strategy

Verify all of the following:

- walking past teammates does not constantly trigger reactions
- hard bumps do trigger reactions
- unbraced impacts in runs produce visible knockback and interruption
- braced impacts are noticeably safer
- reactions recover quickly
- reactions do not soft-lock station usage
- remote players see the same hit timing and recovery windows

## Exit Criteria

This milestone is successful when:

- hangar collisions can produce funny, brief shove reactions
- run impacts visibly knock the crew around
- brace meaningfully reduces those effects
- the same reaction-state model is ready for future hook or harpoon pulls
- no ragdoll system is required to get the desired feel
