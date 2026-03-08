# Third-Person Avatar Control Refactor Design

## Context

The current prototype mixes two control styles:

- a Roblox-style third-person builder avatar in the hangar
- a station-driven run client that still behaves more like an abstract crew controller than a real deck-avatar game

The intended game feel is now clear:

- Fortnite-style third-person avatar control
- crosshair-centered camera
- avatar always faces aim direction
- free movement on the shared boat
- soft station interaction instead of global station ownership
- real knockback and overboard moments

This refactor changes the control standard for the entire game.

## Decision

Adopt one unified third-person avatar control model across hangar and run.

The new standard is:

- mouse/crosshair controls camera yaw and pitch
- avatar yaw always follows camera aim yaw
- `W A S D` movement is relative to camera facing
- stations are physical world interactions
- players move freely on the deck
- helm is a soft interaction zone
- brace is usable anywhere on the boat
- repair is proximity-based and spends shared repair materials near damaged sections
- players can fall into the sea and must actively recover

## Goals

- Make the game feel like a real third-person co-op action game instead of a station menu layered on a boat sim
- Keep building and run controls consistent
- Make player position matter during chaos, salvage, repairs, and impacts
- Support funny and dramatic moments like being knocked off the helm or thrown overboard
- Preserve the server-authoritative boat/run model

## Non-Goals

- True ragdolls in this refactor
- Full swimming exploration away from the boat
- Underwater systems
- Replacing the extraction-loop run structure
- Peer-to-peer authority

## Core Control Model

### Camera

- Third-person over-the-shoulder camera
- Crosshair stays centered
- Mouse drives yaw and pitch
- Camera is player-owned and does not drift toward the boat or other framing targets
- Reaction jolts can still offset the camera briefly

### Movement

- Avatar always aligns to camera aim yaw
- `W A S D` moves relative to camera facing
- Jump remains available
- Reactions can interrupt, slow, or displace movement

### Interaction Language

- The player physically moves to the thing they want to use
- Interactions are driven from the avatar and crosshair, not from an abstract station list
- Leaving the usable area or being knocked away ends the interaction

## Run Interaction Model

### Helm

- Helm stays a soft station zone
- The active helmsman must remain inside the helm area to steer
- Boat throttle and steering only come from the active helmsman
- If the player leaves the zone, is knocked away, or goes overboard, helm control drops

### Brace

- Brace becomes a player ability usable anywhere on the boat
- Primary purpose: reduce personal knockback and impact punishment
- It can later contribute to team/boat impact mitigation, but MVP should prioritize personal survival and deck control

### Grapple

- Grapple remains an anchored world tool for now
- The player uses it from the grapple interaction zone with the same crosshair-driven aiming model

### Repair

- Repair becomes a carried action
- The player must move near damaged blocks or damaged sections of the boat
- Repair consumes shared repair material
- Repair no longer belongs to a single fixed repair station

### Overboard

- Players can be knocked off the boat into the sea
- Overboard players enter a limited swim + grab state
- Recovery is active, not automatic
- Valid recovery targets can include ladders, side-grab zones, or climb-back prompts
- Overboard is dangerous but should not turn into full free-swim exploration

## Architecture Impact

### Hangar

The hangar evolves from a third-person builder scene into the first true implementation of the universal controller:

- mouse-look camera
- crosshair-owned facing
- camera-relative movement
- build interactions through avatar position and aim

### Run

The run scene must evolve from station selection plus placeholder crew visuals into:

- real local deck avatar
- real remote deck avatars
- moving-boat-relative traversal
- interact zones for helm and grapple
- anywhere brace
- proximity repair
- overboard transitions and recovery

### Networking

The server remains authoritative for:

- boat motion
- station control
- repair material spending
- damage validity
- overboard state
- recovery success

Clients send intent, movement, and interaction requests. The server resolves gameplay truth.

## Risks

### High Risk

- Moving character traversal on a moving, damageable boat
- Syncing deck avatars cleanly with existing boat authority
- Keeping interactions readable during knockback and overboard chaos

### Medium Risk

- Mouse-look camera changes colliding with current crosshair build logic
- Refactoring existing station logic without breaking the current run loop
- Keeping automated smoke coverage useful during the transition

## Simplifications

To keep the refactor shippable:

- no true ragdolls
- no off-boat free exploration
- no swimming combat
- no full body IK station animations
- soft zones rather than hard lock-in interactions

## Phased Delivery

1. Shared third-person controller foundation
2. Real run deck avatars on the moving boat
3. Interaction refactor:
   - soft helm
   - anywhere brace
   - proximity repair
   - anchored grapple
4. Overboard and active recovery
5. Balance and polish

## Success Criteria

- Hangar and run both use the same core avatar control style
- Players can move freely on the deck while the boat is in motion
- Helm only works from the helm zone
- Brace works anywhere on the deck
- Repair requires physical movement to damaged sections
- Overboard moments are recoverable and meaningful
- The existing extraction loop remains understandable after the refactor
