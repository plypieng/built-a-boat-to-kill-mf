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

## 2026-03-08 Milestone A Shared Builder Foundation

- Replaced the old post-run dock stub with a networked 3D hangar scene that clients enter immediately after connecting.
- Added an authoritative shared blueprint model to `NetworkRuntime`, including:
  - session phase routing between `hangar` and `run`
  - replicated live boat blueprint snapshots
  - authoritative place/remove/launch/return RPCs
  - derived boat stats and launch warnings from the main connected chunk
- Added shared blueprint persistence via `DockState` so the local dedicated server carries the team boat forward between sessions.
- Added the first true 3D co-op builder controls in the hangar:
  - arrow keys for X/Z cursor movement
  - `PageUp` / `PageDown` for height
  - `Q` / `E` to cycle block types
  - `R` to rotate
  - `F` to place
  - `X` to remove
  - `Enter` to launch
- Added the first block set:
  - `core`
  - `hull`
  - `engine`
  - `cargo`
  - `utility`
  - `structure`
- Hooked the current extraction loop back up so launching from the hangar snapshots the current build and derives:
  - max hull integrity
  - top speed
  - cargo capacity
  - repair kit count
  - brace multiplier
- Added headless builder smoke-test roles:
  - `builder_a`
  - `builder_b`
  - `builder_demo`
  - `builder_launch`
- Fixed a teardown bug found in full-loop validation where late run-scene callbacks could fire during the hangar transition and access a null local `multiplayer`.
- Verified builder-only smoke on port `7072`:
  - one client connected into the hangar
  - `builder_a` produced blueprint versions `2 -> 4`
  - server ended at `blueprintVersion=4`, `blocks=8`, `loose=0`
- Verified two-client live co-build on port `7073`:
  - `BuilderA` and `BuilderB` joined the same hangar
  - `BuilderB` edits advanced the shared blueprint to `version=7`, `blocks=11`
  - both clients received the replicated blueprint updates live
- Verified hangar-to-run handoff on port `7074`:
  - `builder_launch` launched the run from the hangar
  - client log reached `Run client ready...`
  - server log switched from `phase=hangar` to `phase=run`
- Verified full hangar -> run -> hangar loop on port `7076`:
  - `builder_launch + autorun-demo + autocontinue-to-dock`
  - run ended `phase=success`
  - server transitioned back to `phase=hangar`
  - no more null-`multiplayer` script errors after the teardown fix

## 2026-03-08 Runtime Block Damage Design

- Approved the next milestone to make the built boat materially matter during the run.
- Approved design decisions:
  - disconnected launch chunks sink immediately
  - impact damage hits a small local block cluster
  - detached chunks remove their gameplay contribution immediately
- Wrote the milestone design doc to `docs/plans/2026-03-08-runtime-block-damage-design.md`.
- Wrote the fallback implementation plan to `docs/plans/2026-03-08-runtime-block-damage-implementation-plan.md`.

## 2026-03-08 Milestone B Runtime Block Damage

- Replaced the run-time placeholder boat assumptions with a real runtime block model derived from the launched blueprint.
- Added server-owned runtime block state:
  - per-block HP
  - destroyed / detached flags
  - connected-chunk recomputation
  - sinking detached chunk snapshots
- Added launch-time loose-chunk handling so disconnected builder chunks now spawn as loose debris and sink immediately instead of silently contributing stats.
- Added localized block damage for:
  - hazard collisions
  - unbraced salvage backlash
- Added aggregate-stat recomputation from the surviving main chunk so chunk loss now immediately affects:
  - top speed
  - hull integrity ceiling
  - cargo capacity
  - repair capacity
  - brace multiplier
- Added immediate cargo spill handling when detached chunk loss reduces cargo capacity below the amount already collected in-run.
- Updated the run client to render:
  - the actual launched block-built boat
  - health-tinted block visuals
  - detached sinking chunk visuals
  - result and HUD fields for blocks destroyed, chunks lost, and cargo lost to sea
- Split the network sync model so:
  - fast boat movement/helm state stays in the regular lean unreliable boat packet
  - runtime block/chunk state replicates separately as a reliable structural snapshot
  - the old ENet MTU warning is gone on clean launch-path verification
- Added deterministic headless verification helpers:
  - `builder_loose_launch`
  - `builder_fragile_cargo`
  - `driver_detach_test`
- Verified launch-time loose sinking with a fresh temporary Godot `HOME` on port `7093`:
  - `builder_loose_launch` produced `version=2`, `blocks=6`, `loose=1`
  - launch result: `active=5`, `detachedChunks=1`, `sinking=1`
  - no oversized unreliable ENet packet warning appeared during bootstrap or launch
- Verified runtime detachment and cargo spill with a fresh temporary Godot `HOME` on port `7095`:
  - `DetachDriver + GrapplerBot + BraceBot`
  - the crew recovered both loot items first
  - the next unbraced collision destroyed the forward structure and detached both cargo blocks
  - result during the run: `active=4`, `destroyed=1`, `detachedChunks=1`, `sinking=1`, `cargoLost=1`
- Re-verified the normal coordinated co-op route with a fresh temporary Godot `HOME` on port `7097`:
  - `DriverBot + GrapplerBot + BraceBot`
  - result: `phase=success`, `cargo_secured=2`, `reward_gold=88`, `reward_salvage=5`
  - final boat state: `destroyed=0`, `detachedChunks=0`, `cargoLost=0`
- Re-verified the post-run return path after runtime block damage on port `7100`:
  - `DriverBot + GrapplerBot + BraceBot`
  - successful extraction returned to `phase=hangar` cleanly
  - fixed a follow-up bug where `--autobuild-role` would rerun after hangar return and immediately relaunch the run
  - `autobuild` roles are now one-shot per client process via `GameConfig`

## 2026-03-08 Desktop Visual Pass

- Added lightweight viewport-capture debug flags:
  - `--capture-frame-path=<png path>`
  - `--capture-frame-delay-ms=<delay>`
- The hangar and run client now save a local viewport PNG after an optional delay, which gives us a deterministic visual-check path even when OS-level window capture is unreliable.
- Re-ran the manual visual pass after Screen Recording was granted using a fresh temporary Godot `HOME`:
  - captured the pre-run hangar at `/tmp/builtaboat-visual-MGgD9I/hangar.png`
  - captured an in-run four-client co-op view at `/tmp/builtaboat-visual-MGgD9I/run.png`
  - captured a post-success hangar reload with banked rewards at `/tmp/builtaboat-visual-MGgD9I/postrun_hangar.png`
- Verified visually:
  - the hangar shows the shared block-built boat and current derived stats
  - the in-run view shows the real runtime block boat, crew placeholders, wreck ring, and hazard marker
  - the successful run rewards persist back into the hangar profile (`Gold 88 | Salvage 5 | Runs 1 | Extracted 1`)
- Visual-readability issues surfaced by the pass:
  - the hangar boat is too small relative to the current camera framing and wide HUD panels
  - the in-run deck labels stack on top of each other once several crew members occupy nearby stations
  - the large hazard sphere reads more like a placeholder debug prop than a shippable encounter marker

## 2026-03-08 Roblox-Style Social Builder Hangar Design

- Shifted the next milestone from a narrow readability-only polish pass to a larger builder-identity pass after clarifying the target feel.
- Approved the new hangar target as `Build a Boat for Treasure`-style social building:
  - third-person builder avatars
  - walking and jumping in hangar
  - short-range avatar-based building
  - tool/gizmo placement in front of the player
  - shared physical build space around the boat
- Locked these decisions:
  - builder UX comes before further run-presentation polish
  - no free build camera in the first pass
  - no true ragdolls yet
  - use a lightweight reaction system first so future impacts and harpoon moments have a gameplay hook
- Wrote the approved design doc to `docs/plans/2026-03-08-roblox-style-social-builder-hangar-design.md`.
- Wrote the fallback implementation plan to `docs/plans/2026-03-08-roblox-style-social-builder-hangar-implementation-plan.md`.

## 2026-03-08 Social Builder Avatar Prototype

- Started implementation on Milestone 1 from the approved Roblox-style social-builder plan.
- Added hangar avatar replication state to `NetworkRuntime`:
  - per-peer hangar position
  - velocity
  - facing
  - grounded flag
- Added a first-pass third-person hangar avatar in `scenes/hangar/hangar.gd`:
  - walk
  - jump
  - gravity
  - follow camera
  - simple builder placeholder visual
- Added solid collision for:
  - the dock
  - placed hangar boat blocks
- Kept the old cursor-based build controls alive temporarily so the builder remains usable while the forward build-tool milestone is still pending.
- Verified a fresh single-client desktop hangar pass on port `7120`:
  - captured `/tmp/builtaboat-hangar-Fml9Z6/hangar-avatar.png`
  - local avatar rendered correctly in third-person
  - the boat remained visible in front of the player
  - roster now reports hangar avatar position
- Re-verified the existing hangar-to-run launch regression on port `7123`:
  - `builder_launch` still transitioned from hangar into the run client cleanly
  - server switched from `phase=hangar` to `phase=run`
- Partial multiplayer validation:
  - multiple clients still connected to the same hangar on ports `7121` and `7122`
  - the simultaneous visual pass for remote-avatar readability is not fully signed off yet and still needs a cleaner shared-frame capture or manual desktop check
- Next implementation target is unchanged:
  - replace the detached cursor with the short-range forward build tool tied to avatar position

## 2026-03-08 Crosshair Build Tool Prototype

- Continued Milestone C by replacing the hangar's detached cursor movement with a Roblox-style short-range build tool.
- Added camera-crosshair targeting in `scenes/hangar/hangar.gd`:
  - the build ghost now raycasts from screen center
  - placement snaps against the dock or an existing block face
  - removal now targets the aimed block directly instead of the old free cursor cell
  - a small centered `+` crosshair now marks the build aim point
- Added authoritative range checks in `autoload/network_runtime.gd`:
  - hangar edits now validate against the builder avatar position on the server
  - block placement and removal silently reject out-of-range requests
- Updated the headless builder helpers so automation still obeys the new rule:
  - autobuild roles now reposition the local hangar avatar near the requested cell
  - the builder waits briefly before placing so the avatar state reaches the server first
- Verified on port `7133`:
  - a headless hangar client connected cleanly after the first pass
  - an initial smoke run caught GDScript Variant inference warnings in the new targeting helpers
  - fixed those warnings before continuing with gameplay checks
- Verified on port `7134`:
  - `BuilderA` and `BuilderB` still co-built successfully under the new range validation
  - server advanced the shared blueprint from version `1` to `7`
  - individual placements still landed at the expected target cells
- Re-verified hangar-to-run handoff on port `7134`:
  - `LaunchBot` still changed the session from `phase=hangar` to `phase=run`
  - the launched boat used the updated blueprint version `7`
  - derived run stats reflected the larger built boat (`top_speed=11.3`, `cargo_capacity=5`, `brace_multiplier=1.44`)

## 2026-03-08 Reaction System Design

- Approved the first shared reaction-system milestone for both the hangar and the run.
- Locked these design decisions:
  - reactions should briefly affect control, not just visuals
  - hangar player-to-player bumping is part of the fun
  - bump reactions should trigger only on hard collisions
  - brace should reduce knockback and interruption during runs
  - harpoon-style pulls should use a hooked or dragged reaction state first, not true ragdolls
- Wrote the approved design doc to `docs/plans/2026-03-08-reaction-system-design.md`.
- Wrote the fallback implementation plan to `docs/plans/2026-03-08-reaction-system-implementation-plan.md`.

## 2026-03-08 Reaction System Prototype

- Implemented a first-pass authoritative reaction system across both the hangar and the run.
- Added shared reaction state in `autoload/network_runtime.gd`:
  - hard hangar bumps now trigger paired knockback reactions
  - run hazard impacts and salvage backlash now trigger impact reactions
  - reaction state is replicated to all clients and survives hangar/run scene transitions
  - peers under an active reaction lock cannot claim stations, brace, grapple, repair, or keep driving normally
- Added hangar-side feedback in `scenes/hangar/hangar.gd`:
  - clearer build-ghost feedback for `ready`, `occupied`, `out of range`, and blocked cells
  - local and remote builder avatars now show stumble/tilt reactions instead of needing ragdolls
  - local hangar movement and jump are briefly interrupted during hard bumps
  - camera jolt and roster text now reflect active reactions
- Added run-side feedback in `scenes/run_client/run_client.gd`:
  - crew placeholders now visually react to impact state with offset and tilt
  - active reactions add short control interruption and softer recovery handling
  - station labels and crew nameplates were simplified so reaction callouts remain readable
  - the chase camera now picks up a small local jolt on new reactions
- Added `--autohangar-role=<bumper_left|bumper_right>` in `autoload/game_config.gd` for repeatable bump smoke tests.
- Fixed a real regression during implementation:
  - the first run-side smoke caught a GDScript parse failure in `scenes/run_client/run_client.gd`
  - explicit typing on the new reaction-adjusted crew target position fixed the scene load
- Fixed a second real regression during verification:
  - a quick two-client hangar teardown reintroduced the old ENet disconnect send error
  - coalescing disconnect flushes with a short delay and suppressing broadcasts during that window removed the error again
- Verified a fresh unbraced run reaction path on port `7143`:
  - `CrashBot` launched from hangar, claimed helm, and collided twice
  - final boat snapshot showed `hull_integrity=66.9`, `last_impact_damage=18.0`, and `collision_count=2`
  - server logs confirmed heavy unbraced impacts released helm before the driver reclaimed it
- Verified a fresh braced comparison on port `7145`:
  - `DriverBot` plus `BraceBot` launched from hangar and hit the same hazard pattern
  - final boat snapshot showed `hull_integrity=94.9`, `last_impact_damage=6.14`, and `collision_count=2`
  - server logs confirmed braced impacts kept helm ownership stable and applied much lower damage
- Re-verified the hangar bump path on port `7147`:
  - `BumperLeft` and `BumperRight` collided in hangar and triggered the new bump reaction
  - both clients disconnected cleanly afterward without the old ENet send error returning

## 2026-03-08 Friends MVP Roadmap

- Approved a fun-first friends MVP target with manual server launch and manual join flow.
- Locked the MVP definition around:
  - shared social hangar building
  - shared extraction runs
  - meaningful reward feedback into future boat choices
  - stability for repeated two-to-four-player tests
- Explicitly cut from MVP:
  - public matchmaking
  - PvP
  - true ragdolls
  - deep crafting trees
  - seamless world expansion
  - art-first production asset work
- Wrote the approved roadmap to `docs/plans/2026-03-08-friends-mvp-roadmap-design.md`.
- Wrote the fallback implementation plan to `docs/plans/2026-03-08-friends-mvp-roadmap-implementation-plan.md`.
- Approved the first delivery slice as `Week 1: social builder feel`, focused on:
  - hangar camera framing
  - stronger selected-block and placement feedback
  - better remote builder readability
  - clearer launch readiness and seaworthiness warnings

## 2026-03-08 Week 1 Social Builder Polish

- Implemented the first MVP delivery slice in `scenes/hangar/hangar.gd`.
- Improved hangar presentation:
  - added simple dock props and warm lights to frame the build space
  - shifted the camera into a stronger over-shoulder composition that keeps the boat more central
  - resized the HUD panels so they leave more room for the 3D hangar
- Improved builder readability:
  - added a dedicated build-tool panel with palette, selected-part stats, and current rotation
  - added a separate placement panel that calls out range, blocking, and target state more clearly
  - updated the crosshair and build ghost so they reflect placement state more cleanly
  - made the in-world cursor label shorter so the HUD carries the detail instead of the 3D scene
- Improved social readability:
  - local builders now show `You` instead of the old generic `Builder` label
  - remote builders now use more distinct avatar colors
  - the roster now shows names and relative distance instead of raw peer ids and coordinates
- Improved launch readiness feedback:
  - added a dedicated launch-readiness summary with clearer safe/risky messaging
  - updated the launch button text to reflect riskier launches such as loose chunks
  - kept the permissive launch model while making the consequences easier to understand
- Fixed a real scene-transition bug during validation:
  - the new hangar HUD could ask the local avatar for `global_position` during hangar-to-run teardown
  - guarding the local-avatar lookup removed the `!is_inside_tree()` error during scene change
- Verified a fresh visual capture on port `7148`:
  - captured `/tmp/builtaboat-week1/hangar-v2.png`
  - confirmed the new build-tool, placement, and launch-readiness panels render in the hangar
- Verified a two-client co-build regression on port `7149`:
  - `BuilderA` and `BuilderB` still advanced the shared blueprint from `v1` to `v7`
  - no new builder-range or placement regressions appeared
- Verified a fresh hangar-to-run handoff on port `7150`:
  - `LaunchBot` launched from `phase=hangar`
  - the server switched cleanly to `phase=run`
  - the hangar teardown error no longer appeared

## 2026-03-08 Week 2 Reward Loop Design

- Approved the Week 2 MVP slice as a compact reward loop built around new block unlocks rather than upgrade tiers.
- Wrote the approved design doc to `docs/plans/2026-03-08-week-2-reward-loop-design.md`.
- Wrote the fallback implementation plan to `docs/plans/2026-03-08-week-2-reward-loop-implementation-plan.md`.
- Locked the first unlock catalog to:
  - `reinforced_hull`
  - `twin_engine`
  - `stabilizer`
- Locked progression ownership to the shared host/server profile so the builder palette and unlock flow stay authoritative.

## TODOs

- Implement the Roblox-style social builder hangar:
  - better local co-op readability once multiple avatars build on the same section
- Finish multiplayer visual verification for the new hangar avatars with a clearer shared-frame or hands-on local co-op pass.
- Return to narrower readability polish after the new social builder baseline exists.
- Re-verify the full `hangar -> successful run -> dock/hangar` handoff after the hangar builder changes land.
- Add a hooked/dragged reaction state for future harpoon pulls before attempting any true ragdoll work.
- Add stronger client-side feedback for block loss, such as recent-hit flashes, clearer chunk-detach messaging, and better destroyed-block readability.
- Decide whether repairs should remain aggregate hull patches or start targeting specific damaged block clusters.
- Decide whether cargo stored in detached cargo blocks should eventually be visualized per block instead of using aggregate overflow rules.
- Decide whether the dock scene should eventually become the default post-connect lobby instead of a post-run handoff only.

## Suggestions For Next Agent

- Start from Milestone B’s runtime block model rather than the old aggregate-only boat assumptions.
- Use a fresh temporary Godot `HOME` for deterministic smoke tests so local saved blueprints do not affect verification.
- Treat the next hangar milestone as a social third-person builder, not a static editor polish pass.
