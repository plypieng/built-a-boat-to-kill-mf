# Week 3 Procedural Encounter And Onboarding Design

Date: 2026-03-08

## Overview

This document captures the approved Week 3 MVP slice for the desktop-first Godot prototype. The goal is to make runs feel less single-path and easier for first-time players to understand without abandoning the current extraction-loop structure.

The approved direction is:

- keep the extraction-loop core
- add one new optional co-op encounter
- add one new ambient hazard family
- make both of them seed-driven and procedurally varied in a lightweight, controlled way
- add contextual onboarding prompts for the key steps of the loop

## Extraction Loop Stays Intact

The Week 3 milestone does not replace the current structure.

The run should still be:

1. launch from the hangar
2. enter a seeded run
3. collect rewards from optional stops
4. choose whether to keep pushing or extract
5. lose unbanked run rewards if the boat sinks before extraction

This is important because the current game identity is about calculated risk. Week 3 adds variety inside that structure rather than converting the game into an endless roguelite voyage.

## Approved Content Pair

The recommended pair is:

- `distress rescue` as the new co-op encounter
- `squall-front` as the new ambient hazard family

This pairing is approved because it improves both dimensions of variety:

- one more memorable stop
- one more kind of sea pressure

## Distress Rescue Encounter

The rescue event should feel different from the existing wreck salvage loop.

Recommended moment-to-moment flow:

- the crew spots a flare, beacon, or smoke marker from a damaged life raft or broken skiff
- the boat diverts into a rescue zone
- the helm must hold position at low speed
- the grappler must secure the rescue capsule or emergency crate
- the crew remains vulnerable while the rescue stabilizes
- once completed, the rescue grants a meaningful extraction reward package

Recommended first-pass reward:

- shared bonus gold
- shared bonus salvage
- one bonus patch kit

Those rewards should still only matter if the crew extracts successfully. They are added to the run bank, not instantly made permanent.

## Squall-Front Ambient Hazard

The new ambient hazard should feel like the sea itself changing mood, not just another floating obstacle.

Recommended behavior:

- one or two visible storm bands appear in the run
- entering a squall reduces readability and control confidence
- the band applies drag to the shared boat
- timed surge pulses create brace pressure while inside the squall
- crews can cut through the band for speed or route around it for safety

The squall must affect route or timing decisions rather than acting as pure decoration.

## Procedural Approach

Week 3 should use `seed-driven procedural placement and variation`, not a fully emergent generator.

What should vary procedurally:

- rescue placement archetype
  - left detour
  - right detour
  - post-wreck side lane
- squall-front layout
  - one or two bands
  - crossing angle and lane pressure
- small parameter ranges
  - rescue radius
  - rescue hold duration
  - rescue reward bonus
  - squall pulse interval
  - squall drag and pulse intensity

What should stay controlled:

- the wreck still exists
- extraction still remains reachable and fair
- the run should not procedurally soft-lock the crew
- the content should remain easy to test by seed

This gives replay value without making the run unreadable or unfair.

## Run Integration

The recommended Week 3 flow becomes:

1. launch from hangar
2. navigate to the wreck salvage stop
3. optionally divert to a distress rescue
4. optionally cut through or route around a squall-front
5. extract before overcommitting

This preserves the current loop while adding more decisions during the middle of the run.

## Rescue Gameplay Rules

Recommended first-pass rules:

- at most one rescue event per run
- rescue is optional
- rescue only completes while:
  - the boat is inside the rescue zone
  - the boat is below rescue speed
  - the grappler has initiated the rescue
- rescue progress decays if the crew leaves the zone or moves too fast
- once completed, the rescue cannot be farmed repeatedly

This keeps the encounter distinct from the wreck while reusing familiar crew roles.

## Squall Gameplay Rules

Recommended first-pass rules:

- one or two squall bands per run
- the boat can safely avoid them, but the route may be longer
- while inside a squall:
  - top speed is reduced by drag
  - periodic surge pulses trigger impact-style reactions
  - brace reduces the damage and interruption from those pulses
- the squall should not instantly kill the run by itself unless the crew is already in a bad state

This keeps the hazard meaningful but fair.

## Onboarding Prompts

Week 3 should add lightweight contextual prompts rather than a heavy tutorial sequence.

Prompt targets:

- build in hangar
- launch from the hangar
- slow down at wreck salvage
- brace incoming impacts and surge pulses
- complete a rescue hold
- extract before the crew loses the boat

Prompt style:

- short one- or two-line hints
- shown only when contextually relevant
- designed to clarify the next good action, not explain the whole game

These prompts should reinforce the extraction mindset:

- if you have loot aboard, getting greedy is risky
- if you overstay or mis-handle the sea, the run can still collapse

## Follow-Up Control Arc

The approved follow-up progression idea should be preserved in planning, but not implemented in Week 3:

- early boats should feel weak and raft-like
- weak helm plus optional paddle assist is the recommended starting handling model
- better control should come through upgrades over time

This is intentionally deferred so Week 3 stays focused on content variety and onboarding.

## Error Handling

The procedural layout system should never:

- place rescue and extraction in an impossible conflict
- trap the crew inside an unavoidable squall
- spawn a rescue in a location the current boat cannot physically approach

If a generated setup fails validation, the system should fall back to a simpler safe layout.

## Testing

Week 3 verification should cover:

- multiple seeds producing different rescue and squall layouts
- rescue completion and reward banking
- rescue failure or abandonment without breaking the run
- squall pressure with and without brace
- contextual onboarding text changing at the right moments
- full hangar -> run -> extraction -> hangar flow still working

## Success Criteria

Week 3 is complete when:

- at least two seeded run layouts feel noticeably different
- the rescue encounter feels distinct from wreck salvage
- squalls influence route or timing decisions
- first-time players receive enough context to understand build, loot, brace, rescue, and extract
- the extraction loop remains the central tension of the run
