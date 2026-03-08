# Week 3 Procedural Encounter And Onboarding Implementation Plan

Date: 2026-03-08
Depends on: `docs/plans/2026-03-08-week-3-procedural-encounter-and-onboarding-design.md`

## Objective

Add a seed-driven rescue encounter, a seed-driven squall hazard family, and lightweight contextual onboarding prompts while preserving the existing extraction-loop structure.

## Note

The `writing-plans` skill was not available in this session, so this file is the direct fallback implementation plan for the approved Week 3 design.

## Delivery Principle

Keep Week 3 controlled and testable. The goal is to add replayable variety and clearer onboarding, not to build a full procedural event director.

## Scope

- add one procedural rescue encounter per run
- add one procedural squall hazard family with one or two bands per run
- add contextual onboarding prompts in hangar and run scenes
- keep wreck salvage and extraction intact

## Suggested Implementation Order

1. `Seeded layout generation`
   - derive rescue placement and squall layout from `run_seed`
   - validate that the layout remains fair and reachable

2. `Rescue run-state and server logic`
   - add rescue state fields to the authoritative run state
   - add rescue initiation, hold progress, completion, and reward banking

3. `Squall run-state and server logic`
   - add squall definitions to the run state
   - apply drag and timed pulse pressure while the boat is inside a squall

4. `Client presentation`
   - render rescue marker and rescue zone
   - render squall bands clearly enough for route planning
   - surface rescue/squall state in the HUD

5. `Onboarding prompts`
   - add short contextual prompts in hangar and run
   - cover build, launch, wreck handling, rescue, brace, and extraction

6. `Verification`
   - run seed-based smoke checks across at least two layouts
   - confirm the existing extraction loop still resolves cleanly

## Expected File Touches

- `autoload/network_runtime.gd`
- `scenes/run_client/run_client.gd`
- `scenes/hangar/hangar.gd`
- `scenes/run_server/run_server.gd`
- `README.md`
- `progress.md`

## Suggested Verification

- clean server/client boot after adding rescue and squall state
- at least two seeds with different rescue positions and squall layouts
- one successful rescue completion run
- one run where the crew ignores or abandons the rescue
- one squall pass with brace mitigation
- full `hangar -> run -> hangar` extraction check after the new content lands

## Risks

- do not let the procedural layout create unfair or impossible routes
- avoid making the rescue feel like a second copy of the wreck encounter
- keep the squall readable from a distance so it supports planning rather than surprise punishment
- keep onboarding prompts short enough that they help instead of cluttering the HUD
