Original prompt: Analyze the feasibility of a browser-based multiplayer 3D ocean survival extraction game based on the provided concept prompt, using the develop-web-game skill as reference.

## 2026-03-06 Feasibility Notes

- Repo state: empty git repository with no commits and no existing web-game scaffold.
- Local environment: `node`, `npm`, and `npx` are installed and available for a future prototype loop.
- Preliminary product read: the concept is feasible for a browser game if scoped as a staged multiplayer co-op extraction game first, not as a full Tarkov-scale PvPvE sandbox on day one.
- Biggest technical risks: synchronized modular boat damage, large procedural world streaming, server-authoritative multiplayer, water/physics performance, and economy/security for extraction progression.
- Best MVP direction: 1-4 player instanced co-op, one shared ocean seed per match, single boat HP, limited biome set, grappling loot collection, extraction timer pressure, and lightweight enemy/hazard simulation.

## 2026-03-06 Godot Direction

- Target shifted toward `desktop-first` using Godot rather than browser-first.
- Approved product direction:
  - co-op only for v1
  - up to 4 players per run
  - one shared team boat per run
  - boat construction only between runs
  - dedicated authoritative server
  - launch with ship HP plus damage zones, while preserving per-block data for future full per-block damage
- Recommended architecture:
  - Godot client for rendering, input, UI, and local feel
  - Godot headless dedicated server for run authority and replication
  - bounded seeded ocean instances made of connected regions instead of a giant seamless world
  - co-op role design based on stations/actions such as helm, brace, grapple, repair, and navigation
- Approved design doc written to `docs/plans/2026-03-06-godot-coop-ocean-extraction-design.md`.
- Fallback implementation plan written to `docs/plans/2026-03-06-godot-coop-ocean-extraction-implementation-plan.md` because the `writing-plans` skill is not available in this session.

## 2026-03-06 Milestone 0 Scaffold

- Installed Godot via Homebrew cask. Verified CLI version: `4.6.1.stable.official.14d19694e`.
- Added initial Godot project scaffold:
  - `project.godot`
  - autoloads for runtime config and networking
  - boot router, client boot scene, and headless server boot scene
  - placeholder run client/server scenes
  - helper scripts `tools/run_client.sh` and `tools/run_server.sh`
  - root `README.md` and `.gitignore`
- Verified:
  - `bash -n` passes for helper scripts
  - direct headless Godot boot succeeds with `godot --headless --path . --quit-after 2 -- --server --port=7000 --seed=424242`
  - wrapper server launch succeeds with `./tools/run_server.sh --port=7001 --seed=777`
  - a non-headless client launch starts the project without immediate parse errors
- Not yet verified interactively:
  - clicking through the client UI and joining a running server
  - scene-to-scene transition from client boot into the placeholder run scene after connect
  - full peer roster sync with multiple real clients

## 2026-03-06 Connect Flow Validation

- Adjusted launch mode detection so headless execution does not automatically force server mode.
- Added CLI test flags:
  - `--autoconnect`
  - `--quit-after-connect-ms=<n>`
- Fixed a client parse error caused by Variant inference in `client_boot.gd`.
- Fixed a placeholder run-scene camera error by moving the `look_at()` call after the camera enters the tree.
- Removed a duplicate bootstrap RPC so the client only receives one run-seed bootstrap on join.
- Verified end-to-end automated handshake:
  - server launched with `./tools/run_server.sh --port=7002 --seed=999`
  - headless client joined with `godot --headless --path . --quit-after 300 -- --host=127.0.0.1 --port=7002 --name=Verifier --autoconnect --quit-after-connect-ms=1000`
  - server log showed connect, register, heartbeat with 2 peers, disconnect, and return to 1 peer
  - client log showed connect, run bootstrap, run scene load, and auto-quit

## 2026-03-07 Milestone 1 Shared Boat Prototype

- Added a server-authoritative shared boat state to `NetworkRuntime`.
- Added explicit helm claiming and per-peer input forwarding.
- Added server-side boat simulation for:
  - position
  - heading
  - speed
  - throttle and steer state
- Updated the run client to:
  - render the replicated boat transform
  - follow the boat with a third-person camera
  - show helm/driver/boat HUD state
  - support local keyboard controls
  - support headless autodrive via CLI flags for automated tests
- Updated the run server to simulate and log the authoritative boat state.
- Verified automated movement path:
  - server launched with `./tools/run_server.sh --port=7012 --seed=333`
  - headless client joined and drove with `godot --headless --path . --quit-after 400 -- --host=127.0.0.1 --port=7012 --name=DriverBot --autoconnect --autodrive-ms=1800 --autodrive-throttle=1.0 --autodrive-steer=0.2 --quit-after-connect-ms=2600`
  - server log showed helm claim, movement, drift-down after input stopped, disconnect, and stable post-disconnect state
  - client log reported final replicated boat position and heading before auto-quit

## 2026-03-07 Crew And Brace Expansion

- Added visible placeholder crew members on the shared boat, with the active driver highlighted.
- Added replicated hazard state and floating hazard markers on the client.
- Added server-authoritative brace handling with collision mitigation, hull integrity tracking, and collision count.
- Added headless auto-brace support via CLI flags for repeatable hazard tests.
- Fixed broadcast behavior so disconnects do not trigger ENet send errors when multiple clients are connected.
- Verified hazard mitigation comparison:
  - unbraced run on port `7021` ended at `82.0` hull integrity after one impact
  - braced run on port `7022` ended at `93.0` hull integrity after one impact
- Verified two-client crew sync smoke test on port `7024`:
  - `DriverBot` claimed helm and drove
  - `Deckhand` stayed connected as a second crew member
  - both clients ended with matching replicated boat state
  - server handled both disconnects without network send errors

## 2026-03-07 First Run Loop Slice

- Replaced the old hotkey-only placeholder client flow with station-based interaction:
  - `helm`
  - `brace`
  - `grapple`
- Added in-world station markers, station selection/cycling, ownership prompts, and station-aware crew placement.
- Added shared loot targets plus a server-authoritative grapple action that moves loot into run cargo.
- Added an extraction buoy with server-side extraction rules based on:
  - cargo present
  - boat position within radius
  - low enough boat speed
- Added success/failure result handling to the client, including a result overlay and final run summary.
- Added `--autorun-demo` plus `--autoclaim-station=<id>` CLI support so the first complete loop can be smoke-tested headlessly.
- Expanded server heartbeat logging to include run phase, cargo, extraction progress, and station occupancy.
- Verified success-path run on port `7033`:
  - client command: `godot --headless --path . --quit-after 1600 -- --host=127.0.0.1 --port=7033 --name=DemoCaptain --autoconnect --autorun-demo --quit-after-connect-ms=12000`
  - result: `phase=success`, `cargo_secured=1`, `loot_remaining=0`, extraction progress reached `1.6/1.6`
  - final boat state remained intact with `hull_integrity=100.0`
- Verified failure-path run on port `7034`:
  - client command: `godot --headless --path . --quit-after 3000 -- --host=127.0.0.1 --port=7034 --name=CrashBot --autoconnect --autoclaim-station=helm --autodrive-ms=22000 --autodrive-throttle=1.0 --autodrive-steer=0.0 --quit-after-connect-ms=23000`
  - result: `phase=failed`, `hull_integrity=0.0`, `collision_count=6`
  - failure reason: `Hull destroyed in open water.`

## 2026-03-07 Co-op Pressure Slice

- Expanded the shared boat stations to:
  - `helm`
  - `brace`
  - `grapple`
  - `repair`
- Replaced the single floating loot pickup with a wreck salvage POI that contains multiple loot targets.
- Added wreck-specific salvage rules:
  - the boat must be inside the wreck ring
  - the boat must be below salvage speed
  - unbraced salvage surges damage the hull and add breaches
- Added breach-driven damage pressure:
  - breaches reduce effective top speed
  - breaches leak hull integrity over time
  - the repair bench clears breaches and restores hull integrity
- Added `--autorun-role=<driver|grapple|brace|repair>` for headless role-based smoke tests.
- Verified three-client co-op salvage run on port `7042`:
  - `DriverBot` held the boat over the wreck and then piloted extraction
  - `BraceBot` covered both salvage pulls and later braced on the return leg
  - `GrapplerBot` recovered both wreck loot items
  - result: `phase=success`, `cargo_secured=2`, `loot_remaining=0`
  - the crew still took one later collision on the way out, finishing at `77.2` hull with `2` breaches
- Verified repair-pressure soak on port `7043`:
  - `CrashBot` continuously drove through hazards
  - `RepairBot` claimed the repair bench and patched repeatedly
  - result after `8` collisions: `repair_actions=14`, hull still above `90` when both clients disconnected
  - this confirms the repair role is meaningfully counteracting breach pressure in-run
- Ran an exploratory solo autorun pass on port `7044`:
  - solo station swapping successfully recovered both loot items and used the repair bench
  - extraction autopilot still needs tuning for reliable solo completion, so this path should be treated as experimental rather than a primary smoke test

## 2026-03-07 Co-op Route Tuning

- Tuned the driver autorun return route so the coordinated crew leaves the wreck with a left-lane shift before committing to extraction.
- Adjusted the hazard layout to preserve pressure around the wreck and extraction path while leaving one safe coordinated lane.
- Fixed server-side peer enumeration during broadcasts by using `multiplayer.get_peers()` while hosting, which eliminated the disconnect send error seen during multi-client teardown.
- Verified a final four-client coordinated run on port `7049`:
  - `DriverBot`, `GrapplerBot`, `BraceBot`, and `RepairBot` all joined successfully
  - result: `phase=success`, `cargo_secured=2`, `loot_remaining=0`
  - final boat state: `collision_count=0`, `repairs=0`, `hull_integrity=100.0`
  - no ENet send errors appeared during disconnect cleanup

## 2026-03-07 Dock, Repair Economy, And Cache Pass

- Added more human-readable run presentation:
  - objective-focused HUD copy
  - dock resource readout during the run
  - smoother chase camera for helm readability
- Added a local dock profile autoload plus a post-run hangar scene:
  - extracted runs now bank `gold` and `salvage`
  - the dock scene shows total runs, successful extractions, and the last run summary
  - the run scene can auto-continue into the dock scene for verification
- Added run reward fields on the authoritative server state:
  - `reward_gold`
  - `reward_salvage`
  - bonus reward banking from optional encounters
- Converted the repair bench into a limited patch-kit economy:
  - each repair action now consumes one shared patch kit
  - runs start with `3` patch kits
  - the patch-kit limit is now visible in both HUD and result state
- Added a resupply cache encounter:
  - one optional cache positioned on the extraction lane
  - grants `+18 gold`, `+1 salvage`, and `+1 patch kit`
  - recovered via grapple when the crew passes through its zone
- Fixed two behavior regressions uncovered during verification:
  - deferred disconnect broadcasts now avoid the old ENet send error during multi-client teardown
  - helm autopilot now pivots correctly when a target falls behind the boat instead of driving farther away
- Verified a clean four-client co-op run on port `7057`:
  - result: `phase=success`, `cargo_secured=2`, `loot_remaining=0`
  - cache result: `cache_recovered=true`, `bonus_gold_bank=18`, `bonus_salvage_bank=1`
  - payout result: `reward_gold=88`, `reward_salvage=5`
  - boat result: `collision_count=0`, `repair_actions=0`, `hull_integrity=100.0`
  - disconnect cleanup completed without ENet send errors
- Verified dock handoff on port `7059`:
  - headless autorun completed
  - client log reached `Hangar ready: gold=352 salvage=20 runs=4`
- Verified repair-economy pressure on port `7060`:
  - crash test ended `phase=failed`
  - `repair_actions=3`
  - `repair_supplies=0`
  - confirms the patch-kit limit is now a real run constraint rather than unlimited sustain

## 2026-03-08 Live Co-op 3D Builder Design

- Approved the next major milestone as a live co-op 3D boat builder rather than a hangar-upgrades-only slice.
- Approved design decisions:
  - full freeform builder
  - one shared team boat blueprint
  - true 3D bounded build volume
  - 90-degree grid rotation
  - disconnected blocks allowed in hangar
  - disconnected chunks warned about but not blocked at launch
  - disconnected chunks sink immediately at run start
  - runtime chunk detachment and sinking after damage
- Wrote the milestone design doc to `docs/plans/2026-03-08-live-coop-3d-boat-builder-design.md`.
- Wrote a direct implementation-plan fallback to `docs/plans/2026-03-08-live-coop-3d-boat-builder-implementation-plan.md` because the `writing-plans` skill is still not available in this session.

## TODOs

- Lock target session size and whether PvP is required for MVP.
- Choose engine/rendering stack and multiplayer backend.
- Define a vertical slice with one extraction loop and one progression path.
- Decide how much of the modular boat fantasy must exist in phase 1 versus later phases.
- Finish the Godot architecture design sections for progression, persistence, anti-cheat boundaries, and testing.
- Convert the approved design into a concrete implementation plan and milestone breakdown.
- Start Milestone 0 by scaffolding the Godot project, local client/server boot flow, and authoritative shared boat prototype.
- Run an interactive local client/server test in the Godot app and fix any UI or networking issues found there.
- Start Milestone 1 with a replicated shared boat movement prototype once the client connect flow is confirmed.
- Decide whether solo autorun support should remain a dev convenience or become a supported single-player fallback.
- Add at least one manual desktop play pass for station readability, camera feel, and result-screen presentation.
- Decide whether the dock scene should eventually become the default post-connect lobby instead of a post-run handoff only.

## Suggestions For Next Agent

- Start with a feasibility-driven design doc before any implementation scaffold.
- Favor a WebGL-first rendering path with optional future upgrades instead of depending on the newest browser graphics features.
- Keep boat building grid-based and mostly cosmetic/stat-driven at first; defer full per-block destruction until the core loop is fun.
