# Friends MVP Roadmap Design

Date: 2026-03-08

## Overview

This document captures the approved roadmap for reaching a friends-and-family MVP of the current desktop-first Godot prototype. The target is a manual-hosted co-op build where two to four players can build together in the hangar, launch a shared boat into a run, survive hazards, extract rewards, and feel that those rewards meaningfully affect the next run.

The roadmap deliberately avoids public-service infrastructure, final art dependency, and deep simulation expansion. The goal is to make the existing loop fun, readable, and replayable as quickly as possible.

## Approved MVP Definition

The MVP should allow:

- manual server launch plus manual friend join
- two to four players in a shared hangar
- playful third-person co-building around one shared boat
- a shared extraction run with:
  - helm
  - brace
  - grapple
  - repair
  - reaction knockback
  - runtime block damage
  - chunk loss
  - extraction success or failure
- post-run rewards that feed back into future build choices

The MVP should be understandable enough that friends can play without the developer explaining every system live.

## Explicit Non-Goals For MVP

- public matchmaking
- true ragdolls
- PvP
- a giant seamless ocean
- deep crafting trees
- production-ready 3D art
- polished backend account services
- advanced naval physics or full structural simulation
- full harpoon dragging physics

## Recommended Delivery Strategy

Use a fun-first four-week push:

1. Week 1 focuses on the social builder feel in the hangar
2. Week 2 adds a real reward and unlock loop
3. Week 3 adds one more memorable encounter and basic onboarding
4. Week 4 hardens the prototype into a shareable friends build

This path is recommended because the project already has the core extraction prototype, shared builder foundation, runtime block damage, and first reaction system. The fastest route to MVP is making the current loop feel intentional rather than making it much bigger.

## Week 1: Social Builder Feel

### Objective

Make the hangar fun and readable enough that players naturally want to spend time there together before launching.

### Scope

- improve hangar camera framing around the shared boat
- strengthen build ghost and placement-state feedback
- make the currently selected block and rotation easier to read
- improve local and remote builder readability
- make launch readiness and disconnected-chunk warnings clearer
- keep the existing hangar-to-run transition stable

### Success Criteria

- two players can run and build around the boat without confusion
- the camera makes the boat feel like the center of the space
- players can tell why a placement is valid or invalid
- launch feels intentional rather than like a debug scene switch

### Exclusions

- new hazards
- progression economy
- ragdolls
- new encounter families
- new backend/service work

## Week 2: Reward Loop

### Objective

Make successful runs change the next build in an obvious way.

### Scope

- add a simple unlock/store panel in the hangar
- gate a small set of block types or upgrades behind gold and salvage
- make the post-run summary clearer about what changed
- feed the newly unlocked items back into the shared builder palette

### Success Criteria

- one successful run gives the team a reason to rebuild differently
- players can tell what was unlocked, bought, or improved

## Week 3: One More Memorable Ingredient

### Objective

Make the run feel less like a single-path proof of concept.

### Scope

- add one more encounter or hazard family
- add lightweight onboarding prompts for:
  - build
  - launch
  - loot
  - brace
  - extract
- improve objective readability during the run

### Success Criteria

- a new player can understand the loop without live coaching
- runs have at least one more surprising or memorable beat

## Week 4: MVP Hardening

### Objective

Turn the prototype into a build that can be handed to friends for feedback.

### Scope

- bug fixes and disconnect cleanup
- UX polish and balance tuning
- packaged desktop test build
- short host/join instructions
- basic regression smoke checks

### Success Criteria

- friends can launch the server, join, play a few runs, and report useful feedback

## MVP Feature Cuts

To protect the timeline, keep these cuts in force until the MVP is in players’ hands:

- no true ragdolls
- no PvP
- no seamless ocean expansion
- no deep crafting progression
- no art-first asset push
- no major structural physics expansion

## Non-Negotiable MVP Quality Bar

The MVP is only considered successful if all of these are true:

- the hangar is socially fun for a few minutes on its own
- the shared boat build noticeably affects the run
- the run contains real tension from damage, brace, repair, cargo risk, and extraction pressure
- extraction rewards change future choices
- failure feels learnable rather than random
- repeated two-to-four-player tests stay stable enough to iterate on

## Nice-To-Haves

These are welcome if they fit, but they are not required for MVP:

- a second unlock tier
- one extra encounter family
- better hazard presentation
- light branding and packaging polish

## Immediate Recommendation

Start with Week 1 and keep the changes tightly centered on social builder feel:

- better hangar framing
- stronger build-state feedback
- better social readability
- clearer launch readiness

The current project has enough systems to support an MVP. The fastest path now is refinement, not expansion.
