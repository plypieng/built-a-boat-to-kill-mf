# Full HUD Expedition Board Implementation Plan

Date: 2026-03-08
Depends on: `docs/plans/2026-03-08-full-hud-expedition-board-design.md`

## Objective

Implement the approved full HUD redesign in phased order, starting with the in-run gameplay HUD where the readability payoff is highest.

## Note

The `writing-plans` skill was not available in this session, so this file is the direct fallback implementation plan for the approved HUD design.

## Delivery Principle

Redesign the presentation layer first without destabilizing the current gameplay loop. Reuse existing run, hangar, and results data where possible and treat the first pass as a hierarchy-and-behavior redesign rather than a systems rewrite.

## Scope

- redesign the in-run HUD first
- redesign the results overlay second
- redesign the hangar HUD last so it inherits the same visual language
- preserve current gameplay state sources and current networking authority

## Suggested Implementation Order

1. `Run HUD shell`
   - audit the current HUD nodes in `scenes/run_client/run_client.gd`
   - replace the current large text stack with a new structure:
     - top-center objective strip
     - top-right extraction pressure card
     - bottom-right boat survival cluster
     - bottom-left crew/station strip
     - center event callout layer
   - keep the existing world markers and boat camera intact in the first pass

2. `Run HUD messaging cleanup`
   - shorten current onboarding and objective copy
   - convert long explanatory text into:
     - single objective line
     - short event callouts
     - one local action hint where needed
   - preserve only the most important persistent fields

3. `Results HUD redesign`
   - replace the current result overlay with:
     - outcome card
     - reward summary column
     - incident report column
     - return-to-hangar summary strip
   - reuse current secured/lost/reward/chunk-loss data

4. `Hangar HUD redesign`
   - evolve the current compact pass into the approved expedition-board layout
   - make:
     - build card
     - dock ledger
     - crew strip
     - optional detail drawer
   - keep the center dedicated to the boat, crosshair, and build ghost

5. `Visual polish`
   - establish shared color tokens and panel styling
   - align motion/transition behavior across hangar, run, and results
   - tune density and spacing after the first full pass is playable

## Expected File Touches

- `scenes/run_client/run_client.gd`
- `scenes/hangar/hangar.gd`
- `README.md`
- `progress.md`

Potentially:

- shared helper functions or constants if extracting HUD style tokens becomes worthwhile

## Suggested Verification

- clean parse smoke with `godot --headless --path . --quit-after 2`
- GUI capture of the run HUD in at least:
  - normal travel
  - wreck/salvage pressure
  - extraction pressure
  - result screen
- GUI capture of hangar HUD after the final pass
- one full `hangar -> run -> result -> hangar` loop after each phase
- readability check with at least one two-client local session after the run HUD redesign lands

## Risks

- avoid replacing functional clarity with thematic chrome
- avoid drifting back into large always-open prototype text panels
- keep the center screen clear enough for driving and grappling
- do not let hangar polish delay the run HUD, which is the highest-value redesign area

## Recommended First Milestone

Start with `Run HUD first`.

Specifically:

- rebuild the run HUD layout in `scenes/run_client/run_client.gd`
- preserve current data bindings
- shorten wording dramatically
- add a new event-callout layer

This is the fastest way to make the game feel more intentional and less prototype-heavy.
