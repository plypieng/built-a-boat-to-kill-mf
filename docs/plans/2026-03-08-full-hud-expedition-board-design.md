# Full HUD Expedition Board Design

Date: 2026-03-08

## Overview

This document captures the approved full HUD redesign for the desktop-first Godot prototype.

The approved direction is:

- redesign the full HUD system across `hangar`, `run`, and `results`
- use a `hybrid` tone:
  - playful and social in the hangar
  - tense and pressure-heavy during runs
- use a `mixed` HUD model:
  - screen HUD for critical survival state
  - world-anchored markers where location matters
- anchor the visual language in a `scrappy nautical expedition` world

The signature direction is `Expedition Board`:

- each major HUD cluster should feel like a clipped field plate, dock notice, salvage tag, chart fragment, or repaired instrument panel
- the HUD should not read like a generic shooter overlay with nautical colors pasted on top

## Intent

The HUD is for:

- 2-4 players building together in the hangar
- coordinating stations and risk during runs
- understanding exactly what was secured or lost at the end of a run

It must help players:

- understand the current objective in under a second
- read survival-critical state without hunting
- coordinate roles without relying on voice chat for every detail
- connect run outcomes back to the next build decision

It should feel:

- social and toy-like in the hangar
- compact and pressurized in the run
- conclusive and motivating in results

## Product World

### Domain

The HUD should draw from:

- chart tables
- harbor notices
- rescue boards
- buoy markers
- stamped cargo manifests
- patched hull plates
- salvage tags
- flare markers
- rope rigging logic

### Color World

The approved color world is:

- `storm blue`
- `oxidized teal`
- `sea-glass green`
- `buoy orange`
- `chart cream`
- `rust brown`
- `brass yellow`

These colors should feel like they belong to a harbor-and-expedition world rather than a clean sci-fi or military UI.

### Signature

The HUD signature is:

- a crew expedition board made of clipped panels, stamped status plates, field notes, and repaired instruments

That signature should appear across:

- hangar build/readiness surfaces
- in-run boat survival cluster
- results incident manifest

### Defaults To Avoid

The redesign should explicitly avoid:

- generic shooter bars
- esports-style neon overlays
- military tactical chrome
- clean mobile-game cards
- giant always-open debug panels

## HUD Architecture

The HUD should work as one coherent system with three modes:

- `Hangar HUD`
- `Run HUD`
- `Results HUD`

The system rule is:

- top and center are for world/navigation and immediate objective
- bottom-left leans toward crew and control coordination
- bottom-right leans toward boat state and pressure
- large overlays appear only for results, failure, or rare confirmations

This keeps the system learnable while allowing each mode to emphasize different priorities.

## Hangar HUD

The hangar should feel like a `crew build yard`, not a settings screen.

### Priorities

- current build action
- launch readiness
- dock progression totals
- selected unlock
- crew presence
- optional deeper inspection

### Layout

Recommended layout:

- `Top-left build card`
  - selected block
  - rotation
  - placement state
  - launch readiness
- `Top-right dock ledger`
  - gold
  - salvage
  - unlocked parts
  - selected unlock
  - buy action
- `Bottom-left crew strip`
  - connected crew
  - nearby social state
  - quick controls
- `Center crosshair + ghost + one placement line`
  - keep the center visually open
- `Optional detail drawer`
  - full boat stats
  - warnings
  - last run summary
  - deeper seaworthiness notes

### Behavior

- the hangar should default to `compact`
- the boat must remain the visual hero
- deep detail should expand only on demand
- the launch action should feel important without creating constant modal friction

## In-Run HUD

The run HUD is the highest-priority redesign area.

It should feel `tight, pressured, and readable`.

### Priorities

- current objective
- hull and survival state
- brace timing and repair pressure
- cargo and extraction risk
- crew/station ownership
- short-lived event drama

### Layout

Recommended layout:

- `Top-center objective strip`
  - one current instruction only
  - examples:
    - `Brace for surge`
    - `Hold steady for grapple`
    - `Return to extraction`
    - `Cargo at risk`
- `Top-right extraction pressure card`
  - cargo onboard
  - extraction readiness
  - rescue/cache status
  - squall warning if relevant
- `Bottom-right boat survival cluster`
  - hull integrity
  - breach state
  - speed
  - patch kits
  - brace readiness
  - cargo capacity / overflow pressure
- `Bottom-left crew and station strip`
  - who owns helm / brace / grapple / repair
  - whether the local player is useful, idle, or blocked
  - one short local action hint
- `Center crosshair and world markers`
  - grapple-valid target highlights
  - extraction marker
  - station prompts
  - hazard markers
- `Mid-screen event callouts`
  - short stamped alerts
  - examples:
    - `Chunk Lost`
    - `Cargo Washed Overboard`
    - `Brace Perfect`
    - `Engine Offline`
    - `Rescue Secured`

### Design Rules

- reduce persistent text walls
- rely on:
  - one active objective
  - one survival cluster
  - one crew strip
  - short event punches
- keep the center clean enough for steering, grappling, and hazard reads

The `boat survival cluster` is the main signature element for the run. It should read like a repaired expedition instrument tile rather than a default health/stamina HUD.

## Results HUD

The results screen should feel like a `salvage manifest + incident report`.

### Priorities

- what was secured
- what was lost
- how the boat failed or survived
- what changed permanently in the hangar

### Layout

Recommended structure:

- `Center outcome card`
  - `Extracted`
  - `Sunk`
  - `Cargo Lost`
- `Left column: secured and earned`
  - cargo secured
  - cargo lost
  - gold earned
  - salvage earned
  - rescue/cache bonus
- `Right column: incident report`
  - blocks destroyed
  - chunks detached
  - systems lost
  - hull state on finish
- `Bottom strip: back to hangar`
  - new totals
  - new unlock affordability
  - prompt to rebuild and relaunch

### Behavior

- success should feel like a dock receipt or secured manifest
- failure should feel like a wet stamped report, not a giant red arcade death card
- both states should teach the player something about the next build decision

## Visual Language

### Palette Use

- `storm blue`
  - structural dark
- `chart cream`
  - neutral labels and calm emphasis
- `oxidized teal`
  - standard system state
- `sea-glass green`
  - safe / ready / success
- `buoy orange`
  - caution / interactable / salvage
- `flare red-rust`
  - danger / chunk loss / failure

### Typography

- headings should feel like stamped harbor signs or chart headers
- body text should stay blunt and practical
- personality should come from layout, tokens, framing, and hierarchy more than decorative body fonts

### Surface And Layering

- translucent layered plates, not giant opaque slabs
- clipped or pinned card shapes when possible
- corner density is acceptable
- center-screen obstruction is not

### Motion

- hangar motion can be softer
- run alerts should be short and snappy
- results can enter with more ceremony
- only animate things that matter:
  - objective changes
  - impact alerts
  - extraction completion/failure
  - unlock/reward reveal

## Behavior Rules Across All Modes

- default to compact
- expand only on demand
- present one primary objective at a time
- prefer short-lived event callouts over permanent verbosity
- use world markers when location matters
- use screen HUD when survival readability matters

## Recommended Implementation Order

The approved implementation order is:

1. `Run HUD first`
   - top objective strip
   - bottom-right survival cluster
   - bottom-left crew strip
   - event callouts
   - extraction pressure card
2. `Results HUD second`
3. `Hangar HUD third`

The run HUD redesign should establish the full visual language first, because it has the strongest gameplay payoff.

## Current Code Integration

The first implementation pass should reuse the current data model rather than inventing new systems.

Primary current integration points:

- `scenes/run_client/run_client.gd`
  - current run HUD construction
  - onboarding text
  - extraction visuals
  - result overlay
- `scenes/hangar/hangar.gd`
  - current hangar HUD construction
  - progression and blueprint status
- `autoload/network_runtime.gd`
  - current replicated state source for boat, run, stations, extraction, and progression

The first pass should mainly change:

- hierarchy
- layout
- labels
- color tokens
- event behavior

It should not block on new gameplay systems.

## Success Criteria

The full HUD redesign is successful when:

- players can tell what matters without reading paragraphs
- the run feels more tense and professional immediately
- the hangar feels social and open instead of menu-like
- the result screen clearly bridges one run into the next build decision
- the entire system feels like one expedition-board language rather than disconnected prototype screens
