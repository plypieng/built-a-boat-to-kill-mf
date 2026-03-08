# Week 4 Windows Playtest Hardening Design

Date: 2026-03-08

## Overview

This document captures the approved Week 4 MVP hardening slice for the desktop-first Godot prototype. The goal is to turn the current prototype into a Windows-shareable friends build without changing the core authoritative-server architecture.

The approved direction is:

- target Windows friends playtests first
- keep the server authoritative
- add a simpler host/join entry flow for manual playtests
- improve onboarding and status clarity
- harden the prototype into a package that friends can realistically run

## Architecture Stays Server-Authoritative

Week 4 does not switch the game to peer-to-peer or client-authoritative play.

The approved architecture remains:

- dedicated authoritative server owns run state, boat state, damage, extraction, and rewards
- clients connect to that authoritative server
- physics and gameplay outcomes stay server-validated

For playtests, the approved usability improvement is a `simple host mode`, not a different authority model.

That means:

- one friend can host a local authoritative server more easily
- the host still joins as a client
- friends still join by IP

This preserves the long-term architecture while lowering friction for Windows playtests.

## Week 4 Goal

Week 4 should produce a `Windows-shareable friends build`.

That means the game should support:

1. one player starting an authoritative server easily
2. one or more friends joining by IP
3. co-building in the hangar
4. launching into a run
5. surviving hazards, rescue pressure, and extraction
6. returning to the hangar with results and meaningful progression

The core goal is to make real friend tests possible without developer handholding.

## Approved Scope

Week 4 should focus on four areas:

- `host and join flow`
- `Windows packaging`
- `onboarding and readability cleanup`
- `stability and usability hardening`

This is deliberately a refinement milestone, not a new feature-expansion milestone.

## Host And Join Flow

The entry flow should feel like a playable test build rather than a developer tool.

Recommended additions:

- `Host Game`
- `Join Game`
- player name field
- host IP field
- port field or default port display
- clearer connection-state messaging

For MVP, host mode can still use a local dedicated-server process or equivalent helper path under the hood. The important part is that the player does not need to think in terms of raw developer commands.

## Windows Packaging

Week 4 should prepare a practical Windows playtest bundle.

Recommended package structure:

- Windows client build
- Windows dedicated server build
- short host/join instructions
- optional helper launch scripts for host and client

The aim is not storefront-quality packaging. The aim is that a friend can reasonably follow the instructions and get into a game.

## Onboarding And Readability Cleanup

Week 4 should improve how the game teaches itself.

The current prompts already cover the basic loop, but Week 4 should make them more cohesive across:

- connect/boot flow
- hangar building
- launch readiness
- run goals
- extraction and result return

Recommended prompt behavior:

- concise and action-oriented
- no tutorial walls
- errors should explain what to do next
- connection failures should sound understandable, not technical

## Stability And Usability Hardening

Week 4 should tighten the prototype around actual friends-playtesting pain points.

Priority areas:

- cleaner server-missing or bad-IP handling
- clearer transitions between hangar and run
- clearer result and return-to-hangar messaging
- repeated-session reliability
- fewer confusing status changes during autorun and normal manual use

The quality bar is not perfection. The quality bar is “friends can complete repeated sessions without the prototype feeling brittle or mysterious.”

## Explicit Non-Goals

To protect the MVP timeline, Week 4 should not include:

- new encounter families
- raft/paddle control progression
- true ragdolls
- sea monsters
- public backend services
- matchmaking
- deep art replacement
- major physics rewrites

These are valid later steps, but they are not part of MVP hardening.

## Recommended Implementation Order

1. clean up the boot/connect scene into a friend-readable entry flow
2. add or polish host-mode behavior while preserving authoritative server ownership
3. improve onboarding and status messaging in connect, hangar, run, and result return
4. prepare Windows export and package layout
5. run repeated friend-style smoke tests for host, join, play, extract, fail, and reconnect/error handling

## Testing

Week 4 verification should cover:

- Windows export sanity for client and server
- host starts a local authoritative server and joins
- second player joins by IP
- full `hangar -> run -> hangar` success path
- failure path with clear result messaging
- bad-IP or unavailable-server handling
- repeated sessions without state confusion

## Success Criteria

Week 4 is complete when:

- Windows friends can get into the same session without developer intervention
- the game still uses an authoritative server
- the core loop is understandable enough without live coaching
- packaging and instructions are good enough for manual playtests
- the current prototype survives repeated sessions with acceptable reliability
