# Third-Person Avatar Control Refactor Implementation Plan

## Context

The `writing-plans` skill is not available in this session, so this file is the fallback implementation plan for the approved control refactor.

## Milestone 1: Shared Third-Person Controller Foundation

### Goal

Establish the new Fortnite-style control standard in a safe first slice.

### Scope

- Add mouse-look yaw/pitch ownership to the local avatar controller
- Make avatar yaw follow camera aim yaw
- Keep movement camera-relative
- Preserve crosshair-centered building
- Keep reaction interruptions compatible with the new controller

### Files Likely Touched

- `scenes/hangar/hangar.gd`
- `scenes/run_client/run_client.gd`
- shared input helpers if extracted

### Exit Criteria

- Hangar feels like an over-the-shoulder builder/controller
- Camera no longer behaves like a scene framing camera
- Crosshair targeting still works

## Milestone 2: Real Run Deck Avatars

### Goal

Replace placeholder run presence with real traversing avatars on the boat.

### Scope

- Add local run-avatar controller
- Add remote run-avatar replication
- Attach deck movement to the moving boat frame
- Keep station markers and gameplay loop intact while traversal lands

### Files Likely Touched

- `scenes/run_client/run_client.gd`
- `autoload/network_runtime.gd`

### Exit Criteria

- Players can move on the moving boat
- Other players appear as deck avatars instead of static placeholders
- Traversal remains stable in multiplayer

## Milestone 3: Interaction Refactor

### Goal

Refit the current stations and support actions to the new avatar model.

### Scope

- Helm becomes a soft zone
- Brace becomes an anywhere action
- Grapple remains anchored
- Repair becomes proximity-based near damaged blocks/sections
- Remove dependence on global station selection UI for the core interaction loop

### Exit Criteria

- Helm drops if the player leaves the helm area
- Brace can be triggered from anywhere on deck
- Repairs require movement to damage
- Grapple still works in the extraction loop

## Milestone 4: Overboard State

### Goal

Make falling into the sea a real recoverable state.

### Scope

- Overboard detection
- Limited swim + grab movement
- Ladder/edge recovery targets
- Server-authoritative recovery validation
- Basic team readability for overboard state

### Exit Criteria

- Players can be knocked into the sea
- They can actively recover
- Overboard does not soft-lock the run

## Milestone 5: Balance And UX Polish

### Goal

Make the new controller and interactions readable enough for playtests.

### Scope

- Tune knockback and reaction timing
- Tune deck movement on a moving boat
- Improve prompts for helm, repair targets, and overboard recovery
- Rebalance hazards now that player position matters more

### Exit Criteria

- Friends can understand the new deck movement model without live coaching
- The run remains tense rather than chaotic in a confusing way

## Verification Plan

### Automated

- Headless parse smoke after each milestone
- Deterministic temporary-`HOME` smoke flows for hangar and run
- Multiplayer join/build/run verification after networked avatar changes

### Manual

- Hangar over-the-shoulder movement feel pass
- Deck traversal feel pass
- Helm takeover and loss pass
- Repair-near-damage pass
- Overboard and climb-back pass

## Recommended Starting Point

Begin with `Milestone 1` only.

Do not mix overboard, proximity repair, and run-avatar replication into the same first code pass. The controller foundation needs to feel right before the rest of the gameplay layers move onto it.
