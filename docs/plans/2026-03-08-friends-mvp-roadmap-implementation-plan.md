# Friends MVP Roadmap Implementation Plan

Date: 2026-03-08
Depends on: `docs/plans/2026-03-08-friends-mvp-roadmap-design.md`

## Objective

Execute a four-week push toward a manual-hosted friends MVP for the current Godot prototype without expanding scope into public services or major new simulation systems.

## Note

The `writing-plans` skill was not available in this session, so this file is the direct fallback implementation plan for the approved roadmap.

## Delivery Principle

Every week should end in a build that still works end to end. Avoid deep refactors that leave the shared hangar, run, or dock loop temporarily broken. Prefer visible gains over hidden architecture changes unless stability demands otherwise.

## Week 1: Social Builder Feel

### Goals

- Make the hangar feel playful and readable for co-building
- Strengthen the current third-person builder loop
- Improve the launch handoff without touching progression yet

### Tasks

- Reframe the hangar camera so the boat stays central and readable
- Improve selected-block presentation in the HUD
- Make placement feedback easier to scan:
  - valid
  - occupied
  - blocked
  - out of range
- Improve remote builder readability:
  - clearer nameplates
  - better presence around the boat
  - less noisy roster text
- Improve launch readiness feedback:
  - seaworthy callout
  - disconnected-chunk warning language
  - clearer launch button state
- Keep headless builder smoke coverage working

### Exit Criteria

- two-player building is readable without explanation
- the boat looks like the center of the hangar
- launch warnings are understandable at a glance
- the hangar still transitions cleanly into the run

## Week 2: Reward Loop

### Goals

- Make extraction rewards alter future building options

### Tasks

- Add a simple unlock/store panel to the hangar
- Gate a small subset of block options or block upgrades
- Reflect unlock state in the builder palette
- Improve dock/hangar summary after a run

### Exit Criteria

- one successful run creates a meaningful next-run build decision

## Week 3: Content And Onboarding

### Goals

- Make the run more legible and slightly more varied

### Tasks

- Add one more encounter or hazard family
- Add lightweight onboarding prompts
- Clarify objective messaging in run

### Exit Criteria

- a new player can follow the main loop without live coaching

## Week 4: Hardening

### Goals

- Prepare a build that can be handed to friends for real feedback

### Tasks

- package desktop playtest build
- tighten disconnect, join, and teardown behavior
- run regression smoke passes
- tune hangar readability and run balance
- write short host/join instructions

### Exit Criteria

- repeated friends tests are realistic without developer babysitting

## Suggested Week 1 Technical Slice

Work mainly in:

- `scenes/hangar/hangar.gd`
- `autoload/network_runtime.gd`
- `README.md`
- `progress.md`

Suggested implementation order:

1. camera and scene framing improvements
2. selected-block and placement-state HUD improvements
3. remote avatar readability cleanup
4. launch readiness and warning polish
5. verification and documentation

## Suggested Week 1 Verification

- single-client desktop capture pass in hangar
- two-client headless hangar co-build smoke
- hangar hard-bump smoke
- hangar-to-run launch handoff smoke

## Risk Notes

- Do not let Week 1 turn into an art pass
- Avoid adding unlock logic early; that belongs to Week 2
- Keep new UI simple enough that it does not bury the 3D hangar
- Preserve deterministic headless smoke paths while polishing manual feel
