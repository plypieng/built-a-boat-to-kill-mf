# Roblox-Style Social Builder Hangar Implementation Plan

Date: 2026-03-08
Depends on: `docs/plans/2026-03-08-roblox-style-social-builder-hangar-design.md`

## Objective

Turn the current shared hangar builder into a playful third-person co-op build space where players can walk, jump, stand on the boat, and place blocks from a short-range forward build tool.

## Note

The `writing-plans` skill was not available in this session, so this file is the direct fallback implementation plan for the approved design.

## Delivery Strategy

Ship the builder in slices that become human-playable as quickly as possible. The first target is not polish; it is proving that multiple players can physically run around the same boat and build from their own positions.

## Milestone 1: Playable Hangar Avatars

### Goals

- Add local and remote builder avatars to the hangar
- Make the hangar feel like a physical multiplayer space

### Tasks

- Add a lightweight hangar avatar data model to authoritative session state
- Add local avatar control:
  - walk
  - jump
  - gravity
  - grounded detection
- Add remote avatar replication for connected peers
- Add a third-person follow camera for the local player
- Add dock collision and avatar spawn points
- Update hangar HUD so it still works with the new camera and movement model

### Exit Criteria

- two clients can connect to the same hangar and move around visibly
- local movement feels responsive enough for early playtests
- remote avatar positions replicate cleanly

## Milestone 2: Forward Build Tool

### Goals

- Replace the detached editor cursor with an avatar-based build tool
- Make build range matter

### Tasks

- Add selected block type and rotation state to each avatar
- Add forward build ghost targeting from avatar aim or facing
- Snap the ghost to the build grid
- Add valid/invalid placement visuals
- Add configurable build range checks
- Update authoritative build validation to include avatar range
- Keep place/remove and block cycling inputs simple and toy-like
- Preserve existing autobuild helpers where possible, or adapt them to drive the new tool path

### Exit Criteria

- the local player can place and remove blocks only within range
- out-of-range edits fail cleanly
- accepted edits still replicate to all clients

## Milestone 3: Walkable Shared Boat

### Goals

- Let players stand on and build from the current boat
- Make the boat feel like a shared physical object in hangar

### Tasks

- Add collision generation for placed boat blocks in hangar
- Make collision update when blocks are added or removed
- Support walking and jumping onto the boat
- Ensure builder avatars remain stable when standing on placed blocks
- Keep the current blueprint visuals readable while adding collision

### Exit Criteria

- players can climb onto the built boat
- blocks are walkable enough for collaborative building
- add/remove operations do not leave obviously broken collision behind

## Milestone 4: Co-op Builder Readability And Reactions

### Goals

- Improve social readability of the builder
- Add reaction hooks without introducing ragdolls

### Tasks

- Polish local and remote avatar readability:
  - labels
  - colors
  - distance clarity
- Improve build ghost clarity against sky, water, and placed blocks
- Refine hangar camera framing for nearby boat work
- Add simple reaction states:
  - stumble
  - knockback
  - brief recovery lockout
- Expose reaction hooks so future run mechanics can reuse them

### Exit Criteria

- building around other players remains readable
- reaction states exist and can interrupt motion briefly
- no full ragdoll dependency is introduced

## Milestone 5: Regression And Launch Handoff

### Goals

- Preserve the existing build-to-run handoff
- Make sure the new hangar still feeds the current extraction loop cleanly

### Tasks

- Re-verify shared blueprint persistence
- Re-verify hangar-to-run launch after avatar-based building
- Re-verify multiple clients can build and then launch together
- Re-verify disconnected chunk warnings still work
- Re-verify run launch still snapshots the correct blueprint version

### Exit Criteria

- the social builder still launches into the current run loop reliably
- no major regression appears in the build/run handoff

## Suggested Data Additions

Freeze early schemas for:

- `HangarAvatarState`
- `HangarAvatarInput`
- `BuildToolState`
- `BuildValidationResult`
- optional `ReactionState`

## Technical Notes

### Movement Authority

- use client-responsive avatar movement with server correction
- do not block this milestone on perfect character-netcode sophistication

### Build Authority

- keep all blueprint edits server-authoritative
- range validation must happen on the authoritative side

### Collision

- prefer stable, simple solid collisions over fancy dynamic physics
- avoid introducing body pushing or unstable rigidbody interactions between players

### Reactions

- use a simple reaction system only
- explicitly defer real ragdolls until later impact-heavy run mechanics justify them

## Suggested First Sprint

Focus the first sprint on proving the social builder fantasy on screen.

### Sprint Scope

- local and remote hangar avatars
- third-person follow camera
- walk and jump
- dock collision
- forward build ghost
- in-range place/remove validation

### Sprint Exit Test

- launch two clients into the same hangar
- move both avatars around the same boat
- place and remove blocks from different physical positions
- confirm out-of-range placement is rejected
- confirm both clients still see the same live shared blueprint
