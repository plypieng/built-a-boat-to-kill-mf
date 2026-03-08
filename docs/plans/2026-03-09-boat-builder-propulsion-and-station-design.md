# Boat Builder, Propulsion, And Station Design

Date: 2026-03-09

## Overview

This document defines the core identity of the boat-building game layer. The approved direction is:

- the builder is a `bounded sandbox machine designer`
- the boat is made from `Hull`, `Propulsion`, `Stations`, and `Support`
- helm gives `intent`, not direct movement
- propulsion converts helm intent into real motion
- station design should create strong roles without turning the whole run into seated console work
- creative boats should usually be launchable if they float, are traversable, and their required jobs remain usable

The goal is to make the boat itself the main expression of player creativity and team strategy.

## North Star

The player is not building a vehicle skin. The player is building a crewed machine with strengths, labor demands, and failure modes.

The builder should answer:

- what kind of problems this boat solves
- what kind of crew this boat needs
- what kinds of mistakes this boat can survive

The run should answer:

- whether the crew can actually operate the machine they built under stress

## Design Pillars

- `Readable sandbox`
  The system should allow strange and expressive boats, but it must still be legible enough that players understand why a build performs well or poorly.
- `Intent-driven helm`
  The helm steers and gives speed orders. The propulsion package determines how well those orders can be fulfilled.
- `Automation floor, manual ceiling`
  Solo and under-crewed runs must stay viable. Extra crewing and good execution should still matter.
- `Role identity with deck improvisation`
  Helm, salvage, and propulsion support should feel distinct. Brace, rally, recover, and patching should remain mobile actions.
- `Damage changes behavior`
  A damaged boat should steer, accelerate, stabilize, and recover differently, not merely lose HP.

## Goals

- reward boat creativity through meaningful tradeoffs
- make propulsion type a first-class build decision
- preserve co-op role tension during runs
- allow risky, asymmetrical, and specialized boats without encouraging exploit geometry
- make station placement matter without turning the game into a rigid job board

## Non-Goals

- full simulation-grade naval architecture
- free-angle micro-part building
- fully manual propulsion required every second for basic movement
- station systems where every useful action requires permanent occupancy
- hidden formulas players cannot reason about

## High-Level Machine Model

Each boat is the sum of four system layers.

### 1. Hull

Hull defines:

- buoyancy
- drag
- structural integrity
- stability and roll resistance
- deck routeing
- edge safety
- exposed faces for damage distribution

### 2. Propulsion

Propulsion defines:

- thrust generation
- acceleration
- turn response support
- automation floor
- manual ceiling
- environment sensitivity
- operating workload
- propulsion-specific faults

### 3. Stations

Stations define:

- where the crew works
- which roles are persistent claims
- how far the crew must travel
- what jobs can be covered by a floater
- what kinds of panic cascades the crew can recover from

### 4. Support

Support modules define:

- repair coverage
- brace quality
- recovery safety
- propulsion survivability
- damage redundancy
- how forgiving the boat is after mistakes

## Builder Sandbox Rules

The builder should be permissive inside a clear box.

### Hard Constraints

These prevent broken or unreadable boats.

- every blueprint must include:
  - `Core Keel`
  - `Helm`
  - `one primary propulsion package`
  - `one salvage-capable station`
  - `one recovery access module`
- all placed parts must connect to the main structure for launch legality in the long-term builder target
- the boat must meet minimum float margin
- a legal crew spawn area must exist
- a legal walk path must exist from spawn to helm, salvage, propulsion interaction point, and one recovery edge
- required station interaction volumes must not be blocked
- build must fit inside global max width, length, and height bounds

### Soft Warnings

These should not block launch unless a future mode explicitly opts into stricter validation.

- top heavy
- underpowered
- high workload
- poor repair coverage
- poor recovery access
- poor station routeing
- exposed propulsion
- low damage redundancy
- unsafe deck edges
- severe asymmetry

### Launch Rule

If a boat floats, supports traversal, and preserves its core jobs, it should launch even if it is risky.

## Builder Metric Suite

The builder should expose a small set of readable metrics.

- `Float Margin`
  Whether the boat is comfortably seaworthy or barely viable
- `Hull Integrity`
  Aggregate survivability before catastrophic failure
- `Top Speed`
  Maximum sustained speed in ideal conditions
- `Acceleration`
  How fast the boat responds to speed order changes
- `Turn Authority`
  How well the boat follows helm intent
- `Storm Stability`
  Resistance to squall pressure, roll, and crew disruption
- `Crew Safety`
  Likelihood of overboard and downed incidents during chaos
- `Cargo Capacity`
  Run payoff ceiling
- `Repair Coverage`
  How much of the boat can be serviced under pressure
- `Propulsion Health`
  How protected and redundant the drive package is
- `Workload`
  How many jobs the machine demands from the crew
- `Recommended Crew`
  The minimum crew count that can operate the build without constant overload

### Suggested Metric Interpretation

- `Float Margin`
  - below `+5`: illegal
  - `+5 to +10`: barely seaworthy
  - `+11 to +20`: solid
  - `+21+`: forgiving
- `Workload`
  - `0-25`: solo-friendly
  - `26-45`: good for duo
  - `46-65`: wants three players
  - `66+`: full crew machine

## Module Families

### Hull Family

- `Core Keel`
  Mandatory central anchor
- `Pontoon Hull`
  Cheap flotation, good early module
- `Keel Hull`
  Better tracking, efficient centerline support
- `Deck Plate`
  Routeing and safe crew movement
- `Reinforced Prow`
  Front-loaded collision resistance
- `Outrigger Beam`
  Storm stability and crew safety through width
- `Catamaran Beam`
  Split-hull support for advanced layouts

### Cargo Family

- `Cargo Pod`
  Simple haul increase at handling cost
- future cargo variants should emphasize:
  - compact dense cargo
  - wide exposed cargo
  - protected low-volume cargo

### Salvage Family

- `Light Crane`
  Starter salvage station
- `Heavy Winch`
  Safer heavy pulls, slower handling
- `Harpoon Crane`
  More aggressive, higher-risk specialist salvage

### Support Family

- `Repair Bay`
  Improves patch radius and efficiency
- `Utility Bay`
  Broad support for repair and crew safety
- `Brace Frame`
  Improves brace effectiveness in nearby zones
- `Shock Bulkhead`
  Limits structural damage spread

### Recovery Family

- `Ladder Rig`
  Minimum recovery access
- `Guard Rail`
  Reduces crew loss from edges
- `Rescue Net`
  Strong stern-side recovery support

### Propulsion Protection Family

- `Armored Housing`
  Protects adjacent drive modules
- future variants should include:
  - lightweight fairings
  - cooling shrouds
  - sacrificial nacelles

## Propulsion Families

Propulsion is the main differentiator between boat archetypes.

### Manual Paddle Drive

Identity:

- high crew labor
- strong low-speed control
- great reverse behavior
- low top speed
- excellent for rescue and scrappy early-game boats

Behavior:

- strongest when both sides are actively supported
- stamina pressure is part of the boat’s labor story
- remains usable under partial damage better than delicate high-tech drives

### Sail Drive

Identity:

- route-reading and trim mastery
- low constant labor
- strong sustained speed when used well
- weak when mis-trimmed or badly aligned to wind
- highly expressive silhouette potential

Behavior:

- benefits from hull layouts that stay stable in storm bands
- rewards forethought more than panic clicking

### Steam Drive

Identity:

- industrial power
- steady heavy thrust
- good under cargo load
- slow spool-up
- engine-room drama

Behavior:

- strong baseline automation floor
- excellent for work barges and salvage tugs
- needs engineering attention during pressure spikes

### Twin Engine Drive

Identity:

- best acceleration and extraction precision
- most fragile and maintenance-sensitive
- high ceiling for skilled crews
- best fit for cutters and high-risk routes

Behavior:

- thrives on protected engine placement and redundancy
- punishes exposed layouts and neglect

### Auxiliary Propulsion

Late progression should allow one auxiliary package such as a kicker engine or emergency paddle set.

Auxiliaries should:

- improve redundancy
- rescue broken runs
- create hybrid identities
- not replace the need for a meaningful primary propulsion choice

## Station Philosophy

The station system should reinforce role identity without freezing the deck.

### Persistent Stations

These are exclusive claims with clear owners.

- `Helm`
- `Salvage Station`
- `Engineer Console` on engineering-heavy propulsion types
- `Paddle Benches` on labor-heavy propulsion types

### Burst Stations

These are short interactions with high timing value.

- trim lines
- reef points
- vent valves
- cooling bypasses
- rescue net releases
- jam clears

### Deck Actions

These remain mobile and universal.

- brace
- patch
- rally
- recover
- move cargo-side support positionally

### Station Design Rules

- every legal boat needs one clear persistent path to helm and salvage
- propulsion support should only require persistent occupancy if that drive’s identity depends on labor
- burst stations should be solvable by a nearby floater
- no valid build should require four different permanent seats to function at baseline

## Runtime Role Model

### Helm

- owns heading and speed intent
- aligns salvage and extraction
- decides whether the crew can afford optional diversions

### Salvager

- recovers loot and rescue objectives
- times heavy pulls
- creates brace windows for the crew

### Propulsion Support

- improves output ceiling
- handles propulsion-specific interactions and fault recovery
- stabilizes the machine during heavy pressure

### Floater

- patches
- braces
- rallies
- recovers
- covers burst stations when the boat enters crisis

## Control Grammar

The input language should stay consistent across systems.

- `F`
  Context claim, interact, recover, rally, or burst-use
- `G`
  Primary station action
- `R`
  Secondary station action or stabilize action
- `Q/E`
  Cycle selected station or local station setting where relevant
- `Space`
  Brace
- `Shift`
  Burst movement or swim boost

The player should not need to memorize a separate keyboard layout for each propulsion family.

## Starter Content Matrix

Recommended first shipping set:

- `Core Keel`
- `Helm`
- `Pontoon Hull`
- `Deck Plate`
- `Cargo Pod`
- `Light Crane`
- `Ladder Rig`
- `Repair Bay`
- `Guard Rail`
- `Raft Paddles`
- `Steam Tug Drive`

This set is enough to create:

- a scrappy labor boat
- a stable cargo barge
- a basic rescue boat
- a speed-light but fragile runabout

## Builder UX Requirements

The builder must explain the consequences of layout choices.

### Required Panels

- selected part stats and delta preview
- core build report
- warnings and risk list
- recommended crew count
- propulsion report
- station route map

### Required Overlays

- buoyancy and float margin
- walkable deck routeing
- repair coverage
- recovery access
- propulsion exposure
- damage redundancy
- workload by crew count

### Required Plain-Language Readouts

The builder should translate numbers into short phrases like:

- `slow but forgiving`
- `great heavy salvage platform`
- `fast but top-heavy`
- `requires active engineering support`
- `excellent rescue access`
- `unsafe deck edges under storm pressure`

## Balancing Principles

- no part should be generically best
- propulsion packages should define playstyle more than flat power
- support modules should improve survivability indirectly through machine design
- creative weird boats should win through situational advantage, not exploits
- every strong specialization should expose at least one serious weakness

## Decision Log

- Decision: helm controls intent, not direct force
  Alternative: keep direct throttle steering
  Resolution: rejected because it weakens propulsion identity
- Decision: use bounded sandbox rather than free-angle construction
  Alternative: unrestricted build system
  Resolution: rejected because readability and balance collapse too easily
- Decision: keep brace, rally, recover, and patch as deck actions
  Alternative: convert all major actions into seated stations
  Resolution: rejected because it kills improvisational crew movement
- Decision: require automation floor for every propulsion family
  Alternative: fully manual propulsion
  Resolution: rejected because solo and under-crewed boats become too brittle

## Success Criteria

This design is successful when:

- players can describe what their boat is good at in one sentence
- propulsion family meaningfully changes run-time play
- station placement changes crew flow and safety without making runs feel rigid
- asymmetric or strange boats can work if their tradeoffs are honest
- the builder clearly explains why a boat feels bad before launch
- damage changes the behavior of the machine, not only its health total
