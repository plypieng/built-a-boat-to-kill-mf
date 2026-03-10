# Gamelike Run HUD Design

Date: 2026-03-10
Depends on:
- `docs/plans/2026-03-08-full-hud-expedition-board-design.md`
- `docs/plans/2026-03-08-full-hud-expedition-board-implementation-plan.md`

## Overview

This document captures the approved direction for the next run HUD pass based on the latest player-facing mockup feedback.

The new goal is:

- make the HUD read like a `real playable game screen`
- keep the world visible and the center mostly clear
- show only the most important moment-to-moment information by default
- move boat status, cargo pressure, and deeper system detail into `contextual` or `inspect` surfaces

This is a deliberate shift away from the current panel-heavy prototype HUD.

## Core Principle

The default run screen should answer five questions instantly:

1. `Where am I going?`
2. `How much stage pressure is left?`
3. `What am I holding right now?`
4. `Am I personally safe enough to keep playing?`
5. `Is the boat in immediate danger?`

If the HUD is trying to answer more than that all the time, it is too open.

## Approved HUD Pillars

The approved always-on pillars are:

- `Stage Clock`
- `Compass + Goal Strip`
- `Character HP Bar`
- `Center Stamina Bar`
- `Bottom Hotbar`

The approved contextual pillars are:

- `Boat Inspect Overlay`
- `Storage / Cargo Overlay`
- `Station Prompt`
- `Short Event Alerts`

## Default Layout

### Top-left: Stage Clock

Purpose:

- communicate stage pacing and failure pressure at a glance

Content:

- circular stage clock icon
- current stage segment
- three threshold states:
  - `A` start / low pressure
  - `B` softcap / danger rising / nightfall / monster pressure
  - `C` fail threshold

Rules:

- always visible
- no paragraph text
- color transitions should do most of the communication
- use bright daylight colors near `A`
- shift toward warning and red-rust tones as the run approaches `B` and `C`

Per-stage flexibility:

- each run can define different `A`, `B`, and `C` thresholds
- some stages may use:
  - daylight to dusk
  - calm sea to monster surge
  - extraction window to hard cutoff

### Top-center: Compass + Goal Strip

Purpose:

- communicate direction and objective without opening a large info card

Content:

- compass heading
- active waypoint icon
- waypoint label
- distance
- optional small chain preview when a stage has multiple goals

Examples:

- `LIGHTHOUSE 1.2 KM`
- `OUTPOST 320 M`
- `GOAL 2/3: SECOND LIGHTHOUSE`

Rules:

- always visible
- only one active target is emphasized
- if a stage has multiple sequential goals, show them as a short chain:
  - `Lighthouse -> Lighthouse -> Island`
- do not dump the entire task state here

### Lower-left Or Lower-center-left: Character HP Bar

Purpose:

- make player survivability instantly readable

Content:

- compact HP bar
- optional numeric value only if it stays small

Rules:

- always visible
- visually stronger than stamina when health is critical
- healthy state can be pale / chart-cream
- danger state should move toward buoy-orange then flare-red

Behavior:

- pulse lightly only when entering wounded or critical thresholds
- do not animate constantly

### Center: Stamina Bar

Purpose:

- support moment-to-moment movement, bracing, repairing, and emergency actions

Placement:

- centered horizontally
- slightly below the reticle or slightly above the hotbar

Content:

- thin horizontal stamina bar
- no large frame
- optional stamina flash when exhausted

Rules:

- always visible
- must not block steering, grappling, or target reading
- should feel like action feedback, not a stats panel

Behavior:

- normal state: calm and slim
- active drain: brightens slightly
- exhausted state: flashes once, then settles into danger color
- returns quietly as stamina recovers

### Bottom-center: Hotbar

Purpose:

- communicate the player’s current tool/item loadout like a real game action bar

Content:

- slots `1-6`
- active slot highlight
- compact icon + label if possible

Rules:

- always visible
- this should replace the current text-heavy tool belt presentation
- current slot must be readable from the corner of the eye

Inventory rule direction:

- player-held slots are intentionally limited
- the player should not carry the whole run alone
- important materials and survival items should depend on boat storage

## Contextual Overlays

### Boat Inspect Overlay

Purpose:

- communicate hull condition without permanently occupying a corner of the screen

Input:

- hold `Left Alt` to inspect the boat

If `Left Alt` becomes problematic later, the fallback is:

- hold `Tab`

Content:

- hull integrity
- breach state
- storage condition
- major damaged sections
- compact system summary

Presentation:

- overlay should appear near the boat silhouette or as a compact hull card
- white / cream means healthy
- orange / red means near failure
- damaged sections should be visual first, text second

Auto-reveal rules:

- force-show briefly after:
  - heavy collision
  - chunk loss
  - storage loss
  - breach spike
- hide again after the danger window passes

### Storage / Cargo Overlay

Purpose:

- make the boat’s shared cargo limits part of the core game loop

Content:

- current boat storage usage
- overflow risk
- critical cargo loss if storage is destroyed

Rules:

- hidden by default
- show near storage interaction
- show when storage takes major damage

Design direction:

- player inventory is limited
- boat storage is the main haul container
- if storage is lost, the crew should feel that immediately

### Station Prompt

Purpose:

- keep role prompts readable without a permanent crew panel

Content:

- one-line contextual prompt
- examples:
  - `Press F to take Helm`
  - `Hold F to Rally Crew`
  - `Press R to Patch Hull`

Rules:

- appears only when relevant
- near the center or above the hotbar
- never as a full paragraph block

### Event Alerts

Purpose:

- deliver drama without reopening large status cards

Examples:

- `NIGHTFALL`
- `HULL BREACH`
- `STORAGE LOST`
- `LIGHTHOUSE REACHED`
- `CHUNK LOST`

Rules:

- short
- mid-screen
- quick fade
- event words should be visual punches, not explanations

## Visibility Model

### Always visible

- stage clock
- compass + goal strip
- character HP bar
- center stamina bar
- hotbar

### Contextual

- station prompt
- cargo/storage readout
- boat health / hull inspect
- danger alerts

### Hidden unless needed

- deep run stats
- long crew lists
- detailed machine metrics
- large onboarding paragraphs

## Data Mapping To Current Systems

This design should reuse the current gameplay state where possible.

### Stage Clock

Can derive from:

- run phase
- pressure phase
- elapsed run time
- extraction / failure pacing fields

Primary current source:

- `NetworkRuntime.run_state`

### Compass + Goal Strip

Can derive from:

- current objective text
- nearest active POI
- extraction target
- rescue target
- salvage target

Primary current sources:

- `scenes/run_client/run_client.gd`
- waypoint helper functions already used for extraction and POI distance

### Character HP / Stamina

Already available from:

- local avatar state

Primary current source:

- `NetworkRuntime.get_run_avatar_state()`

### Hotbar

Already available from:

- current run toolbelt entries
- selected run tool index

Primary current source:

- `NetworkRuntime.get_toolbelt_entries(NetworkRuntime.SESSION_PHASE_RUN)`

### Boat Inspect

Already available from:

- hull integrity
- breach stacks
- repair supplies
- active block count
- detached chunks
- cargo capacity
- runtime block health information

Primary current sources:

- `NetworkRuntime.boat_state`
- `NetworkRuntime.run_state`

## Interaction Rules

### Character HP

- always on
- never hidden during normal play

### Stamina

- always on
- centered to support action timing

### Boat Inspect

- hold-to-show
- not toggle-to-latch in the first pass
- should disappear immediately when released unless a danger auto-reveal is active

### Hotbar

- number keys switch slots directly
- current slot highlight should be unmistakable

## Motion Rules

- avoid constant animation
- animate only when the player needs help noticing change

Approved motion:

- stage clock threshold transition
- goal swap
- hotbar slot change
- stamina exhaustion flash
- HP danger pulse
- boat inspect reveal
- short danger alerts

## First-pass Screen Composition

The first playable composition should be:

- `top-left`: stage clock
- `top-center`: compass + goal
- `center`: thin stamina bar
- `lower-left or lower-center-left`: HP bar
- `bottom-center`: hotbar
- `contextual`: station prompt, boat inspect, storage alert, event punch

The current large run cards should be removed or collapsed out of the default state.

## Suggested File Touches

- `scenes/run_client/run_hud.tscn`
- `scenes/run_client/run_client.gd`
- `scenes/shared/expedition_hud_skin.gd`
- `README.md`

Potentially:

- a small shared widget helper if the stage clock and hotbar are easier to maintain as reusable HUD pieces

## Implementation Order

1. `HUD shell refactor`
   - replace the current run HUD layout with the new minimal anchor layout

2. `Persistent player layer`
   - add compact HP bar
   - add center stamina bar
   - convert tool belt into a real hotbar

3. `Navigation layer`
   - build compass + goal strip
   - wire active target and distance

4. `Contextual boat layer`
   - add hold-to-inspect overlay
   - add storage risk reveal

5. `Alert pass`
   - convert major events into short center alerts

6. `Playtest tuning`
   - tune screen clutter
   - tune bar scale
   - tune reveal timing

## Success Criteria

This redesign is successful when:

- the run screen looks playable at a glance
- the player can navigate with only the top goal strip and world markers
- the player can track personal survivability without hunting for it
- the player can read stamina in the middle without losing view control
- the boat feels important without requiring a permanent giant boat panel
- storage limitation becomes understandable through UI, not only through text explanation

## Explicit Non-goals For First Pass

- full minimap
- permanent crew roster panel
- permanent machine telemetry panel
- full inventory screen redesign
- deep stage scripting changes

The first pass is a `presentation and interaction hierarchy redesign`, not a full systems rewrite.
