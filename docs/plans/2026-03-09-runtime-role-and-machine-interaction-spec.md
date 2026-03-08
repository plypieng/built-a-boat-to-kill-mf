# Runtime Role And Machine Interaction Spec

Date: 2026-03-09

## Overview

This document defines the run-time interaction model for the new boat machine layer.

It answers:

- what each role does during a run
- which stations are persistent claims and which are burst interactions
- how each propulsion family is actually operated
- how faults and emergencies create role swaps

The approved direction is:

- keep one shared control grammar
- let propulsion family change the meaning of jobs
- preserve mobile deck actions for improvisation
- make crises readable and recoverable

## Shared Control Grammar

The game should teach one input language and then reuse it everywhere.

- `WASD`
  Move on deck or in water
- `Shift`
  Burst movement or swim boost
- `F`
  Context use
  - claim station
  - release station
  - burst interaction
  - recover from overboard
  - rally downed teammate
- `G`
  Primary station action
- `R`
  Secondary station action
- `Q/E`
  Cycle selected station or local station mode
- `Space`
  Brace

This input language should remain stable across propulsion families.

## Station Classes

### Persistent Stations

Persistent stations are long-lived claims that define roles.

- Helm
- Salvage station
- Engineer console
- Paddle bench

Properties:

- one occupant at a time
- claimed with `F`
- released with `F`
- force-released on downed, overboard, destruction, or leaving release range

### Burst Stations

Burst stations are short interactions that create timing decisions.

- trim line
- reef point
- vent valve
- cooling port
- jam clear
- rescue net release

Properties:

- not exclusive claims
- usually `hold F` for `0.75s` to `1.5s`
- any nearby crew can cover them

### Deck Actions

Deck actions remain mobile and universal.

- brace
- patch
- rally
- recover
- reposition

These must not be converted into station-only interactions in the core version.

## Shared Station Rules

- claim radius: `1.25m`
- release radius: `1.6m`
- forced release grace: `0.5s`
- station swap cooldown: `0.35s`
- rally takes priority over normal `F` interactions if a valid downed teammate is in range
- overboard recovery takes priority over normal `F` interactions if the player is in recovery range

## Role Definitions

### Helm

Responsibilities:

- heading
- speed order
- route choice
- extraction positioning
- deciding whether the machine can afford optional content

### Salvager

Responsibilities:

- recover cargo and rescue objectives
- judge whether heavy pulls are safe
- call brace windows
- stop unsafe pulls when propulsion or hull state is unstable

### Propulsion Support

Responsibilities:

- improve thrust ceiling
- stabilize family-specific faults
- manage propulsion burst windows
- restore machine response during crisis

### Floater

Responsibilities:

- patch
- brace
- rally
- recover
- cover burst stations when the machine starts failing

## Crew Count Expectations

### Solo

- helm is primary identity
- propulsion runs mostly on automation floor
- salvage windows should be slower and riskier
- the player should still be able to complete basic runs

### Duo

- one player usually anchors helm
- the second player alternates between salvage and support
- this should feel playable, but strained on high-workload builds

### Trio

- helm
- salvage
- support or floater
- this is the target sweet spot for many mid-game boats

### Full Crew

- helm
- salvage
- propulsion support
- floater

This should be the highest-ceiling crew configuration, not the only viable one.

## Helm Spec

### Inputs

- `W/S`
  Step speed order:
  - Reverse
  - Stop
  - Slow
  - Cruise
  - Full
- `A/D`
  Rudder or heading correction
- `R`
  Center rudder

### HUD

Helm HUD should show:

- speed order
- actual speed
- propulsion efficiency
- turn authority
- active propulsion faults
- hull warning state

### Design Rule

Helm never directly guarantees motion. If the machine is unhealthy, the boat should honestly fail to answer helm intent.

## Salvage Spec

### Inputs

- `F`
  Claim or release salvage station
- `G`
  Primary salvage action
- `Q/E`
  Cycle local target lane or bias where relevant
- `R`
  Emergency cut or cancel

### HUD

- target
- line state
- backlash risk
- brace recommendation

### Design Rule

Salvage is where the crew chooses greed or discipline. It should be one of the main ways good boats and bad boats reveal themselves.

## Propulsion Family Specs

### Raft Paddles

#### Identity

- physical labor boat
- high crew effort
- simple but dramatic

#### Stations

- Helm
- Port Paddle Bench
- Starboard Paddle Bench

#### Inputs

- `F`
  Claim bench
- `Hold G`
  Sustained stroke on that side
- `Tap G`
  Timed burst stroke if rhythm window is active
- `Hold R`
  Brake or reverse that side

#### Runtime Notes

- each side contributes separately to thrust and yaw
- missing one side creates handling drift under load
- sustained rowing spends stamina
- perfect rhythm should increase efficiency, not become mandatory

#### Common Faults

- exhausted paddler
- oar damage
- seat jam
- one-side labor loss due to crew incident

### Sail Rig

#### Identity

- route-smart boat
- environment-reactive propulsion
- moderate labor, high skill

#### Stations

- Helm
- Trim Line
- Reef Point

#### Inputs

- `Hold F` at trim line
  Engage trim
- `Q/E`
  Adjust trim angle
- `Tap R`
  Toggle reef state
- `Tap G`
  Trigger tack assist if conditions allow

#### Runtime Notes

- baseline auto-trim should keep the boat playable
- manual trim should improve efficiency and reduce bad-angle loss
- reefing should trade speed for storm survivability

#### Common Faults

- bad trim
- luff or stall
- sheet jam
- torn sail
- dismast

### Steam Tug

#### Identity

- heavy industrial propulsion
- reliable baseline
- engineering drama under pressure

#### Stations

- Helm
- Engineer Console
- Vent Valve

#### Inputs

- `F`
  Claim engineer console
- `Hold G`
  Stoke or push pressure
- `Hold R`
  dampen and stabilize
- `Q/E`
  Change governor mode
- `Hold F` at vent valve
  dump pressure

#### Runtime Notes

- the console is the main persistent engineering role
- the vent should be a burst station so the floater can save the machine during chaos
- steam should feel slow to spool but hard to completely shut down

#### Common Faults

- low pressure
- overpressure
- boiler leak
- flooded firebox
- steam burst near engine room

### Twin Engine Drive

#### Identity

- precise
- fast
- fragile
- highest control ceiling

#### Stations

- Helm
- Engineering Panel
- Port Cooling
- Starboard Cooling

#### Inputs

- `F`
  Claim engineering panel
- `Hold G`
  tune for response and thrust
- `Hold R`
  cool-conservative mode
- `Q/E`
  Cycle engine sync or side bias
- `Hold F` at cooling port
  clear overheat

#### Runtime Notes

- panel owner manages the machine globally
- cooling ports let the floater cover emergencies
- asymmetry should become a major story when one side is damaged

#### Common Faults

- heat saturation
- engine desync
- cavitation
- one-side failure
- gearbox damage

## Fault States

All propulsion families should share a readable severity model.

### Warning

- soft penalty
- no forced reaction yet
- encourage awareness

### Faulted

- clear penalty
- asks for one targeted response

### Critical

- severe output loss or local danger
- role diversion becomes necessary

The player should always know:

- what failed
- how bad it is
- what action improves it

## Role Swap Patterns

The system is working when crises force sensible role changes.

### Pattern 1

- salvager stops work to brace or cut line
- floater covers recovery
- helm holds position

### Pattern 2

- support player leaves engineering console briefly
- floater vents, cools, or clears jam
- helm chooses slower safer route

### Pattern 3

- one player goes downed or overboard
- remaining crew must choose between role coverage and rescue

## HUD Requirements

### Shared HUD

- station occupancy
- crew status badges
- high-priority fault callouts
- clear objective and next-best-action prompt

### Family HUD Additions

- paddles: side output and stamina burden
- sails: trim state and reef state
- steam: pressure and governor mode
- twin engine: heat and sync state

## Onboarding Requirements

The first strong version should teach by doing.

Recommended contextual prompts:

- `Helm orders speed, propulsion makes it real`
- `This boat wants both paddle sides manned`
- `Trim the sail to recover speed`
- `Boiler overpressure - vent now`
- `Starboard engine hot - use cooling port`

Prompts should be short and action-directed.

## Decision Log

- Decision: use one shared control grammar
  Alternative: family-specific control schemes
  Resolution: rejected because it would overload players
- Decision: let floaters solve burst failures
  Alternative: require the specialist for every correction
  Resolution: rejected because co-op rescues are part of the fantasy
- Decision: keep propulsion-specific HUD contextual
  Alternative: always show all machine detail
  Resolution: rejected because it would clutter the screen

## Success Criteria

This spec is successful when:

- each propulsion family changes how the team works together
- the player can usually tell where they are needed next
- crises create movement and reprioritization
- solo play stays possible at lower efficiency
- co-op play gains meaningful ceiling from coordination rather than button count
