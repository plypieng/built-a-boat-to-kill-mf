# Reaction System Implementation Plan

Date: 2026-03-08
Depends on: `docs/plans/2026-03-08-reaction-system-design.md`

## Objective

Add a shared authoritative reaction-state system that supports funny hard bumps in the hangar and meaningful knockback from unbraced run impacts, while leaving a clean path for future hook or harpoon pulls.

## Note

The `writing-plans` skill was not available in this session, so this file is the direct fallback implementation plan for the approved design.

## Delivery Strategy

Ship the reaction system in slices that become visible and testable immediately. The first goal is not full animation fidelity; it is proving that short authoritative reactions can interrupt control cleanly in both hangar and run.

## Milestone 1: Shared Reaction State

### Goals

- Add a reusable reaction-state shape to authoritative runtime state
- Keep the model scene-agnostic enough for both hangar and run

### Tasks

- Define per-peer reaction data:
  - type
  - strength
  - knockback velocity
  - active timer
  - recovery timer
  - pull vector or target placeholder
- Add replication hooks for reaction-state updates
- Add helpers to clear expired reactions
- Keep the data small enough to replicate without bloating existing fast state packets

### Exit Criteria

- the server can assign and clear reaction states for specific peers
- clients receive enough data to present a reaction consistently

## Milestone 2: Hangar Hard-Bump Reactions

### Goals

- Make hard collisions between builder avatars feel physical and funny

### Tasks

- Detect hard avatar-to-avatar collisions in the hangar
- Gate them by velocity threshold so normal walking contact does not trigger
- Start `bump` reactions on the impacted peers
- Apply short control interruption and knockback in the local hangar controller
- Add simple visual presentation:
  - lean
  - shove
  - brief recovery

### Exit Criteria

- normal movement does not constantly trigger reactions
- hard bumps do trigger a visible short shove or stumble

## Milestone 3: Run Impact Reactions

### Goals

- Make run impacts visibly disrupt the crew
- Tie brace directly into that mitigation

### Tasks

- Trigger `impact` reactions from strong run events:
  - collision impacts
  - unbraced salvage backlash
- Scale knockback and interruption by brace state
- Briefly suppress or damp action input during impact reactions
- Add heavier local camera jolt for the reacting player
- Force station release only on clearly heavy reactions if needed

### Exit Criteria

- unbraced impacts feel dangerous
- braced impacts feel meaningfully safer
- station interaction recovers cleanly after reactions end

## Milestone 4: Hooked Or Pulled Support

### Goals

- Prepare the system for future harpoon or drag mechanics

### Tasks

- Add `hooked` reaction type support to shared data
- Support forced movement from a pull direction or target
- Add input override or suppression while hooked
- Add a short post-pull recovery state
- Provide at least a debug or scripted trigger so the path is testable before real harpoon content lands

### Exit Criteria

- the shared reaction model can represent dragged movement cleanly
- the client can present a pull and recovery without ragdolls

## Milestone 5: Readability And Balance

### Goals

- Keep the system funny, readable, and not overbearing

### Tasks

- Tune hangar bump thresholds
- Tune reaction durations and recovery windows
- Improve label or HUD readability if reactions crowd the scene
- Add short event text or status feedback when useful
- Re-check that repeated impacts do not create long soft-locks

### Exit Criteria

- reaction windows are short and clear
- the hangar stays playful
- run reactions reinforce tension without becoming exhausting

## Suggested Data Additions

- `reaction_state_by_peer`
- `reaction_type`
- `reaction_strength`
- `knockback_velocity`
- `reaction_timer`
- `recovery_timer`
- `pull_vector`
- `brace_applied`

## Technical Notes

### Authority

- server owns reaction start, strength, and timing
- clients should not invent reactions on their own

### Movement

- keep hangar and run movement controllers separate
- both controllers consume the same replicated reaction-state shape

### Presentation

- prefer procedural leaning, shoves, and camera jolts over heavy animation systems
- defer true ragdolls until later high-impact content justifies them

## Suggested First Sprint

Focus the first sprint on the two most visible wins:

- hangar hard-bump reactions
- run impact reactions with brace mitigation

### Sprint Tasks

- add shared reaction replication
- add hangar bump detection and stumble state
- add run impact-triggered control interruption
- add local camera feedback
- add one or two smoke-test hooks for repeatable validation

### Sprint Exit Test

- two avatars can collide hard in the hangar and both react briefly
- unbraced run impacts knock the crew around more than braced ones
- the crew regains control quickly
- no ragdoll system is required to sell the effect
