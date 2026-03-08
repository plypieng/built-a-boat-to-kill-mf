# Run Failure Escalation And Event Pacing Design

Date: 2026-03-09

## Overview

This document defines how runs should create tension once the new boat-building, propulsion, and station systems are in place.

The approved direction is:

- runs should feel like operating a stressed machine, not simply steering toward pickups
- pressure should escalate through interacting subsystems:
  - hull
  - propulsion
  - crew safety
  - cargo risk
- crisis should create role swaps and movement, not only numeric penalties
- the boat remains the primary fail state
- crew health and stamina remain secondary pressure systems that make support roles matter

## North Star

A great run should tell a story like this:

- the crew launches a boat with a clear identity
- early decisions reveal what the build is good at
- the sea starts asking for tradeoffs
- one subsystem slips
- that slip puts pressure on crew movement and role coverage
- the team either stabilizes the machine or loses the boat

The run should not feel like a flat sequence of isolated minigames.

## Run Shape

Recommended high-level structure:

1. `Launch`
2. `Settle Into Machine`
3. `First Pressure Test`
4. `Primary Work Window`
5. `Optional Risk Window`
6. `Extraction Commitment`
7. `Final Hold Or Collapse`

## Pressure Phases

### 1. Launch

Purpose:

- remind the crew what kind of boat they built
- establish station ownership naturally
- let the boat’s handling identity show up immediately

Expected pressure:

- low environmental threat
- moderate workload if the boat is labor-heavy

### 2. Settle Into Machine

Purpose:

- allow the crew to discover whether the build is smooth, overloaded, awkward, or safe
- teach first-time players the jobs through context

Expected pressure:

- low damage risk
- first minor propulsion interactions

### 3. First Pressure Test

Purpose:

- make the crew use at least one defensive response
- establish whether the build is storm-safe, collision-safe, or crew-safe

Expected pressure:

- one obvious hazard cluster
- one brace or routeing decision

### 4. Primary Work Window

Purpose:

- let the boat do the thing it was built to do
- stress the core labor loop of helm, propulsion, and salvage

Expected pressure:

- salvage tension
- cargo commitment
- first meaningful damage or crew incident if the build is sloppy

### 5. Optional Risk Window

Purpose:

- offer a meaningful choice that punishes greed or rewards specialist boats

Examples:

- distress rescue
- cache lane
- shortcut through squall band
- second salvage lane with heavier backlash

### 6. Extraction Commitment

Purpose:

- force the crew to choose safety or greed
- reveal whether the boat remains operational under accumulated damage

Expected pressure:

- higher route pressure
- less room for leisurely repairs
- stronger consequences for propulsion weakness

### 7. Final Hold Or Collapse

Purpose:

- create the last dramatic scramble
- reward stabilizing a damaged machine

Expected pressure:

- extraction requires positioning and control
- damage or crew pressure should matter most here

## Pressure Sources

Pressure should come from four systems at once.

### Hull Pressure

- collisions
- squall pulses
- salvage backlash
- breach accumulation
- chunk loss risk

### Propulsion Pressure

- bad trim
- low pressure
- overheating
- desync
- labor under-coverage
- propulsion damage

### Crew Pressure

- overboard incidents
- downed states
- stamina exhaustion
- long station travel
- unsafe deck edges

### Cargo Pressure

- full cargo making extraction tempting
- heavier mass worsening handling
- cargo pod exposure
- cargo loss making greedy players regret route choices

## Escalation Ladder

The game should recognize a clear escalation curve.

### Calm

- all systems within safe range
- crew can reposition freely
- repairs are optional optimization

### Strained

- one subsystem degraded
- one role is under pressure
- minor damage or fault demands attention

### Critical

- two or more systems interact badly
- one role must abandon its normal task to stabilize
- crew mobility and station coverage become meaningful constraints

### Cascade

- damage, propulsion fault, and crew incidents start feeding each other
- the machine can still be saved, but only through priority decisions

### Collapse

- boat failure is imminent or already underway
- the run should end because the boat lost integrity, buoyancy, or extractability

## Desired Crisis Patterns

The best crises create movement.

### Example: Paddle Boat Crisis

- one side paddler goes downed
- the boat yaws under load
- helm loses precision
- salvage line becomes unsafe
- floater must choose between rally, patch, or brace

### Example: Sail Boat Crisis

- squall hits while sails are unreefed
- bad trim plus drag drops control
- crew is pushed toward edges
- helm must choose route safety over speed

### Example: Steam Barge Crisis

- salvage backlash plus overpressure
- engineer must vent
- floater leaves repair to cover burst station
- helm must hold a slower line while cargo makes the boat sluggish

### Example: Twin Engine Cutter Crisis

- one engine side overheats after repeated boost use
- response goes asymmetric
- high-speed extraction approach becomes dangerous
- engineer must isolate the side or cool it while helm bleeds speed

## Event Pacing Rules

### Rule 1

Do not stack two unreadable spikes at once during the early half of a run.

### Rule 2

Later in the run, allowed combinations should create intentional dilemmas.

Examples:

- rescue plus squall route
- full cargo plus propulsion fault
- salvage backlash plus crew overboard risk

### Rule 3

Every run should include at least one moment where the boat’s specialization feels correct.

### Rule 4

Every run should include at least one moment where the boat’s weakness is exposed.

### Rule 5

The extraction phase should test accumulated damage and crew discipline, not spawn a random unavoidable wipe.

## Encounter Cadence

Recommended cadence for a standard run:

- `0:00 to 0:45`
  launch and machine learning window
- `0:45 to 1:45`
  first hazard pressure and route choice
- `1:45 to 3:15`
  primary salvage or objective work window
- `3:15 to 4:15`
  optional detour or escalation lane
- `4:15 to 5:30`
  extraction commitment
- `5:30+`
  final hold, bonus extension, or collapse

This cadence should stretch or compress based on run tier later, but it is a good target for the first robust version.

## Failure Ladders By Subsystem

### Hull Failure Ladder

- impacts increase breaches
- breaches degrade survivability and handling confidence
- chunk loss reduces stats and can alter routes
- low buoyancy margin creates sink pressure
- sink threshold ends run

### Propulsion Failure Ladder

- minor fault lowers efficiency
- repeated neglect lowers response and thrust
- major fault creates role diversion
- critical fault disables burst or a side of output
- compounded propulsion loss makes extraction unrealistic

### Crew Failure Ladder

- stamina exhaustion limits emergency responses
- overboard or downed events reduce labor coverage
- repeated crew incidents force role collapse
- unresolved incidents lead to more hull and propulsion mistakes

### Cargo Failure Ladder

- more cargo increases greed and mass
- heavier boats punish poor control
- exposed cargo can be lost to sea
- cargo loss should feel painful but not be the direct fail state

## Recovery Windows

A good pacing model needs moments where the team can stabilize.

Recovery windows should come from:

- successfully reefing, venting, cooling, or isolating a fault
- clearing a salvage site
- using a repair bay zone effectively
- hitting a cache or rescue reward
- briefly choosing a safer route instead of a faster one

Do not remove all recovery windows, or runs become coin flips.

## Propulsion-Specific Pressure Profiles

### Paddle Boats

- high labor pressure
- low machine fragility
- strong recovery from single-part damage
- stamina and coverage are the main stressors

### Sail Boats

- medium labor pressure
- medium damage fragility
- high environmental sensitivity
- route decisions are the main stressor

### Steam Boats

- medium labor pressure
- medium-high machine fragility
- strong cargo handling
- pressure and engine room management are the main stressors

### Twin Engine Boats

- low base labor but high precision demand
- high machine fragility
- high payoff for skilled play
- heat and asymmetry are the main stressors

## HUD And Callout Requirements

The game must call out the right problem at the right abstraction level.

### Good Callouts

- `Port paddle side exhausted`
- `Bad trim into headwind`
- `Boiler overpressure`
- `Starboard engine overheating`
- `Crew critical`
- `Repair coverage weak in stern`
- `Heavy salvage pull - brace recommended`

### Bad Callouts

- generic red warnings without action
- unexplained speed loss
- hidden faults only visible in obscure side panels

## Testing

Verification should cover:

- every propulsion family experiencing at least one recoverable fault
- every propulsion family experiencing one crisis pattern that forces a role swap
- extraction remaining possible after moderate damage
- extraction becoming realistically difficult after compounded misplay
- specialist boats getting at least one favorable and one unfavorable run moment
- crisis states feeling understandable rather than random

## Decision Log

- Decision: use subsystem escalation instead of only raw hull pressure
  Alternative: keep most tension on collision damage alone
  Resolution: rejected because the boat would not feel like a machine
- Decision: preserve recovery windows
  Alternative: constant relentless pressure
  Resolution: rejected because the run becomes noisy and unreadable
- Decision: extraction tests accumulated state
  Alternative: extraction as a safe victory circle
  Resolution: rejected because the run’s final minutes need teeth

## Success Criteria

This design is successful when:

- players can tell what subsystem is currently failing
- specialist boats experience both payoff and punishment during the same run
- crises cause players to move and swap priorities
- extraction feels like a real operation, not a cooldown lap
- the boat remains the primary fail state even when crew vitals matter
