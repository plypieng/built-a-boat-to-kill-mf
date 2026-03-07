# Roblox-Style Social Builder Hangar Design

Date: 2026-03-08

## Overview

This document captures the approved design for the next hangar milestone: turning the current shared builder into a playful, Roblox-inspired social build space closer in feel to `Build a Boat for Treasure`.

The hangar should stop behaving like a static editor scene and start behaving like a small multiplayer sandbox. Players spawn as simple third-person avatars, walk and jump around the dock and boat together, and place blocks using a short-range forward build tool rather than a detached editor cursor. The shared boat blueprint remains authoritative and live for everyone.

This milestone intentionally focuses on feel and readability instead of final art fidelity. It should make the builder socially fun before deeper progression or art production begins.

## Approved Product Decisions

- Builder feel target: `Build a Boat for Treasure`-style social building
- Priority: builder UX first, before more run readability polish
- Hangar control mode: third-person avatar control only
- Build interaction style: tool/gizmo projected in front of the avatar
- Placement rule: avatar-based placement with limited build range
- Boat ownership: one shared team boat blueprint
- Edit authority: server-authoritative shared blueprint edits
- Hangar physics scope: simple walk, jump, gravity, and collision
- Character fidelity: lightweight builder avatars, not final rigs
- Impact reactions: reaction system first, true ragdolls later

## Goals

- Make the hangar feel like a shared build playground instead of a menu scene
- Let players physically gather around the boat and build together in real time
- Give player position meaning during building through limited placement range
- Preserve authoritative shared blueprint editing
- Keep the milestone lightweight enough that the current run loop does not need to be reworked

## Non-Goals For This Milestone

- Final production character models or boat art
- True ragdoll simulation
- Physics pushing, grappling bodies, or unstable dynamic hangar builds
- Free camera editor mode
- Complex build permissions or role restrictions
- Material variants, cosmetic inventory, or progression unlocks
- Reworking the run loop beyond whatever is needed to keep the hangar handoff intact

## Experience Goal

The desired player feeling is:

- spawn into the hangar as a visible builder avatar
- run and jump around the dock with other players
- climb or stand on the current boat build
- point a build tool at a section of the boat
- place or remove blocks from where the avatar is physically standing

The crew should feel like they are building together in the same physical place, not editing a shared spreadsheet of blocks.

## Interaction Model

### Avatar Movement

Each connected player gets a lightweight hangar avatar with:

- walk
- jump
- gravity
- grounded state
- collision against the dock
- collision against placed boat blocks

The first version should use simple capsule-based movement, not a full character-controller stack with advanced animation systems.

### Camera

The local player uses a third-person follow camera behind the avatar. The camera should stay readable enough for building while still feeling playful and character-driven.

The first version should:

- stay in third-person at all times
- avoid switching to a detached editor camera
- keep enough elevation to see nearby build surfaces
- remain simple and responsive rather than cinematic

### Build Tool

Building happens through a forward build tool projected from the avatar.

The tool should:

- project a ghost block a short distance in front of the character
- snap to the boat grid
- show valid versus invalid placement state
- rotate in 90-degree increments
- support place and remove actions
- use the player’s currently selected block type

The tool should feel like a toy or handheld building device, not a detached global cursor.

### Placement Range

Placement and removal work only within a limited radius of the avatar.

This is important because it gives movement meaning:

- players need to walk to the side they want to build
- crews can split up and work on different sections
- standing on the boat itself matters

### Co-op Editing Flow

The server still owns the shared boat blueprint.

Clients send intent:

- attempted placement cell
- selected block type
- rotation
- attempted removal cell

The authoritative builder validates:

- current session phase is hangar
- requested cell is inside bounds
- requested cell is in range of the avatar
- occupancy rules are valid
- action is compatible with the current blueprint version

Accepted changes replicate to all clients immediately.

## Scene And System Architecture

The current hangar needs to evolve from a display scene into a small multiplayer play space.

### `HangarAvatar`

Each player should have a replicated hangar avatar that tracks:

- peer id
- position
- velocity
- grounded state
- facing direction
- selected block type
- build rotation

### `HangarWorld`

The hangar world should include:

- dock floor
- simple surrounding water
- current shared boat blocks
- build bounds
- avatar spawn points

Placed boat blocks should become solid walkable surfaces so players can build from on top of the boat.

### `BuildToolState`

Each player derives local build state from:

- avatar transform
- facing direction or camera aim
- selected block type
- current rotation
- target cell
- in-range validation
- occupied/invalid validation

### Replication Boundary

Movement can be client-responsive with server correction.

Block edits remain fully authoritative.

That means:

- avatars should feel responsive to control
- the shared blueprint remains safe and consistent
- invalid local placements may preview but cannot commit

## Reaction System Constraint

This milestone should include a lightweight reaction system but not true ragdolls.

Approved direction:

- use stumble, knockback, brief fallover, or hit-reaction states
- allow these reactions to support future boat harpoons, impacts, and brace failures
- do not introduce full skeletal ragdoll sync yet

Reasons:

- true ragdolls would complicate multiplayer movement and builder readability too early
- a reaction system keeps the game’s physical comedy potential alive without destabilizing the hangar milestone

Future examples that can upgrade from reactions into ragdolls later:

- failed brace during a run
- harpoon yank
- sea monster impact
- severe chunk detachment

## Simplifications For The First Pass

- simple capsule avatars
- minimal animation or pose logic
- no body pushing between players
- no freeform mouse world placement
- no unstable dynamic rigidbody boat physics in hangar
- no final art models
- no true ragdolls

These constraints are intentional so the milestone stays focused on feel, not simulation depth.

## Risks

### Movement Feel

If third-person movement feels laggy or slippery, the whole social-builder fantasy weakens immediately.

### Ghost Placement Readability

If the forward build ghost is confusing in 3D space, players will fight the tool instead of enjoying the build loop.

### Collision Jank

If new blocks become walkable in a way that causes clipping or unstable stepping, the hangar will feel messy fast.

## Recommended Milestone Order

### 1. Playable Hangar Avatars

Add local and remote builder avatars with:

- walk
- jump
- third-person follow camera
- dock collision

### 2. Forward Build Tool

Replace the detached editor cursor with:

- forward block ghost
- range validation
- in-world place/remove flow

### 3. Walkable Shared Boat

Make placed boat blocks walkable so players can:

- climb onto the build
- work from multiple elevations
- physically gather around the same section

### 4. Co-op Builder Polish

Improve:

- ghost clarity
- block feedback
- avatar readability
- simple reaction feedback

### 5. Return To Progression

After the builder feels socially fun, move back to:

- economy
- unlocks
- hangar progression

## Testing Strategy

The milestone should be verified in both headless and desktop passes.

### Functional Checks

- one client can walk, jump, and place blocks in range
- two or more clients can move and co-build together
- out-of-range placement is rejected
- edits replicate consistently
- players can stand on placed blocks

### Feel Checks

- camera makes nearby boat surfaces easy to target
- build ghost reads clearly from the avatar
- movement feels playful rather than stiff
- co-op avatars are readable in a shared scene

### Deferred Checks

True ragdoll behavior is explicitly deferred. Reaction states only need to prove that the system hook exists and can interrupt movement cleanly.

## Success Criteria

This milestone succeeds when:

- the hangar feels like a social build playground
- multiple players can run around and build the same boat together
- building is tied to player position instead of a detached editor camera
- the shared blueprint remains authoritative and stable
- the team can still launch into the current extraction loop after building
