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

## 2026-03-08 Week 2 Reward Loop Implementation

- Implemented shared progression persistence in `autoload/dock_state.gd`:
  - added unlocked block ids to the saved host profile
  - added last-unlock summary persistence
  - added a server-side unlock purchase helper
- Implemented authoritative progression runtime in `autoload/network_runtime.gd`:
  - added replicated progression state for gold, salvage, runs, unlocks, last run, and last unlock
  - moved reward banking onto the server at run resolution
  - gated the shared builder palette by unlocked block ids
  - added a server-validated unlock RPC
  - added the first unlock catalog:
    - `reinforced_hull`
    - `twin_engine`
    - `stabilizer`
- Implemented the hangar-side unlock yard in `scenes/hangar/hangar.gd`:
  - new compact store panel with shared totals, unlock costs, descriptions, and selected-part state
  - new controls:
    - `Z / C` cycle unlocks
    - `V` purchases the selected unlock
  - added autobuild helpers for unlock-flow smoke coverage
- Updated `scenes/run_client/run_client.gd` to read shared progression totals from the replicated runtime instead of the old local-only dock profile.
- Updated `scenes/run_server/run_server.gd` heartbeat logging to include progression totals and latest unlock name.
- Verified on a fresh temporary `HOME`:
  - clean server/client boot on ports `7161` and `7162`
  - one successful autorun extraction banked shared rewards on the host profile
  - a second headless client unlocked `Reinforced Hull` and placed it into the shared blueprint, advancing the blueprint from `v1` to `v2`
  - the saved host profile persisted:
    - unlocked block ids
    - `last_unlock`
    - updated gold and salvage totals
  - restarting the server reloaded the upgraded blueprint and the unlocked part
  - the upgraded `v2` boat launched and completed another full `hangar -> run -> hangar` loop with:
    - `max_hull_integrity=142.4`
    - `active_block_count=6`
    - `phase=success`

## 2026-03-08 Week 3 Procedural Encounter And Onboarding Design

- Approved the Week 3 MVP slice as:
  - one seed-driven procedural distress rescue encounter
  - one seed-driven procedural squall-front hazard family
  - lightweight contextual onboarding prompts
- Confirmed that the game stays extraction-loop first rather than switching to an endless roguelite voyage.
- Confirmed that the future weak-raft-to-better-controls progression arc is a follow-up, not part of Week 3 implementation.
- Wrote the approved design doc to `docs/plans/2026-03-08-week-3-procedural-encounter-and-onboarding-design.md`.
- Wrote the fallback implementation plan to `docs/plans/2026-03-08-week-3-procedural-encounter-and-onboarding-implementation-plan.md`.

## 2026-03-08 Week 3 Procedural Encounter And Onboarding Implementation

- Implemented seed-driven rescue and squall generation in `autoload/network_runtime.gd`:
  - added a procedural run-layout builder keyed from `run_seed`
  - added three rescue archetypes:
    - `left_detour`
    - `right_detour`
    - `post_wreck_lane`
  - added one or two squall bands per run with seeded drag, pulse timing, and damage values
  - added a timed rescue-hold flow that grants bonus gold, salvage, and a patch kit once secured
  - added squall drag and surge pulses that locally damage the runtime block boat and trigger reaction events
- Implemented run-side Week 3 presentation in `scenes/run_client/run_client.gd`:
  - added rescue-ring visuals, flare beacon, and squall band markers
  - added run HUD/objective support for rescue distance, rescue progress, layout label, and squall count
  - added contextual onboarding text for station claiming, wreck salvage, rescue handling, squall pressure, and extraction risk
  - updated autorun helpers so the demo route now visits rescue before cache/extraction
- Implemented minimal hangar onboarding in `scenes/hangar/hangar.gd`:
  - added lightweight builder prompts for move-closer, occupied-cell, loose-chunk, and unlock-yard states
- Updated `.gitignore` to ignore generated Godot `.uid` files so editor-generated IDs do not dirty the worktree during future passes.
- Verified:
  - clean Godot parse smoke after the new rescue/squall/onboarding changes
  - full `hangar -> run -> rescue -> cache -> extraction -> hangar` success on seed `101` using a fresh temporary `HOME`
  - a second seeded success on seed `303` with:
    - `layout_label="Left Detour + 2 squall bands"`
    - `rescue_label="Distress Flare"`
    - `reward_gold=117`
    - `reward_salvage=7`
  - a layout-variation spot check on seed `404` with:
    - `layout_label="Post Wreck Lane + 1 squall band"`
    - `rescue_label="Broken Skiff"`
    - rescue completed before the smoke auto-quit
- Observed during Week 3 verification:
  - the autorun route can now complete the optional rescue cleanly, but unbraced squall pulses still chip the hull if no brace bot is present
  - the extraction-loop structure still reads clearly even with the added rescue detour and weather pressure

## 2026-03-08 Week 4 Windows Playtest Hardening Design

- Approved the Week 4 MVP slice as a Windows-first friends-playtest hardening pass.
- Confirmed that the game stays server-authoritative even in local host mode.
- Locked the playtest architecture to:
  - authoritative server remains the source of truth
  - host mode is only a friendlier way to launch that server locally
  - friends still join by IP
- Wrote the approved design doc to `docs/plans/2026-03-08-week-4-windows-playtest-hardening-design.md`.
- Wrote the fallback implementation plan to `docs/plans/2026-03-08-week-4-windows-playtest-hardening-implementation-plan.md`.

## 2026-03-08 Week 4 Windows Playtest Hardening Implementation

- Implemented a friendlier host/join boot flow in `scenes/boot/client_boot.gd`:
  - replaced the old single connect action with:
    - `Host Game`
    - `Join By IP`
  - added LAN-IP share text
  - added automatic local-host retries while the authoritative server process boots
  - added a new `--autohost` launch flag for repeatable smoke coverage
- Updated `autoload/game_config.gd` to parse `--autohost`.
- Updated `autoload/network_runtime.gd` connection messaging so missing-server and disconnect states explain what to do next in friend-readable language.
- Added `tools/package_windows_playtest.sh`:
  - bundles separate Windows client and server export folders into one playtest directory
  - generates:
    - `HostAndPlay.bat`
    - `JoinFriend.bat`
    - `StartDedicatedServer.bat`
    - `README-playtest.txt`
- Updated `README.md` with:
  - Week 4 host-flow smoke commands
  - Windows packaging helper usage
  - notes about the new host/join flow
- Verified:
  - clean Godot parse smoke after the Week 4 changes
  - local host-mode smoke on port `7170`, with the client launching a local authoritative server and joining it successfully
  - second-client join-by-IP against a locally hosted server on port `7171`
  - full `autohost -> hangar -> run -> extraction -> hangar` loop on port `7172`, including reward banking back into the host profile
  - packaging helper smoke against fake Windows export folders, producing:
    - bundled `client/`
    - bundled `server/`
    - generated `.bat` launchers
    - generated playtest README
- Remaining verification gap:
  - I updated the connection-failure wording for bad-IP or missing-server cases, but I did not capture a full ENet timeout message in a short automated smoke because the timeout window outlasted the quick test budget.

## 2026-03-08 Windows Export Presets And First Friend Bundle

- Added committed Windows export configuration:
  - new `export_presets.cfg` with:
    - `Windows Client`
    - `Windows Dedicated Server`
  - updated `.gitignore` so `export_presets.cfg` stays versioned while generated `build/` and `dist/` folders stay ignored
- Installed Godot `4.6.1.stable` export templates locally under:
  - `~/Library/Application Support/Godot/export_templates/4.6.1.stable`
  - extracted the Windows x86_64 release/debug templates plus console variants and `version.txt`
- Verified real Windows exports from this repo:
  - `godot --headless --path . --export-release "Windows Client" build/windows-client/BuiltaBoat.exe`
  - `godot --headless --path . --export-release "Windows Dedicated Server" build/windows-server/BuiltaBoatServer.exe`
  - both exports produced `.exe` and `.pck` outputs successfully
- Verified the bundle packager against the real exports:
  - `bash tools/package_windows_playtest.sh build/windows-client/BuiltaBoat.exe build/windows-server/BuiltaBoatServer.exe dist/windows-playtest`
  - resulting bundle contains:
    - `client/BuiltaBoat.exe`
    - `client/BuiltaBoat.pck`
    - `server/BuiltaBoatServer.exe`
    - `server/BuiltaBoatServer.pck`
    - `HostAndPlay.bat`
    - `JoinFriend.bat`
    - `StartDedicatedServer.bat`
    - `README-playtest.txt`
- Current limitation discovered during the first real export:
  - the dedicated-server export currently comes out as a Windows GUI-subsystem executable rather than a visible console-window server build
  - this does not block `HostAndPlay.bat`, but it makes `StartDedicatedServer.bat` less transparent for manual server logging
  - if this becomes a pain point for friend tests, the next packaging pass should switch the server preset to a console-template export path

## 2026-03-08 Hangar Camera And HUD Usability Fix

- Added the short design note to `docs/plans/2026-03-08-hangar-camera-hud-usability-fix-design.md`.
- Updated `scenes/hangar/hangar.gd` so the hangar camera explicitly becomes current and reclaims focus while the local avatar moves.
- Reworked the hangar overlay from large full-height panels into smaller corner overlays:
  - compact build and launch panel
  - compact dock/unlock panel
  - smaller bottom-left crew/control panel
  - optional detail panel toggled with `Tab` or `H`
- Kept detailed builder/warning/run history information available, but moved it behind the detail toggle so the center of the scene stays usable for local testing.
- Updated `README.md` to mention the new hangar detail toggle.
- Verified:
  - clean parse smoke with `godot --headless --path . --quit-after 2`
  - local GUI hangar capture on an external server at `/tmp/builtaboat-hangar-fix.png`
  - local GUI host-flow capture at `/tmp/builtaboat-hangar-host-fix.png`
  - both captures show the hangar loading through the avatar-follow camera with the slimmer overlay instead of the old full-height builder panels

## 2026-03-08 Full HUD Expedition Board Design

- Approved the full HUD redesign direction for the entire game:
  - `hangar`
  - `run`
  - `results`
- Locked the visual direction to:
  - `Expedition Board`
  - hybrid playful/co-op tone in hangar
  - tighter extraction pressure during runs
  - mixed screen-HUD + world-marker presentation
  - `scrappy nautical expedition` visual world
- Approved the layout principles:
  - hangar as a dock planning board
  - run HUD centered on objective strip, survival cluster, crew strip, and event callouts
  - results as a salvage manifest plus incident report
- Wrote the approved design doc to `docs/plans/2026-03-08-full-hud-expedition-board-design.md`.
- Wrote the fallback implementation plan to `docs/plans/2026-03-08-full-hud-expedition-board-implementation-plan.md` because the `writing-plans` skill is not available in this session.

## 2026-03-08 Run HUD First Pass

- Implemented the first `Expedition Board` gameplay HUD pass in `scenes/run_client/run_client.gd`.
- Replaced the old run overlay layout with:
  - top-center `Current Order` objective strip
  - top-right `Extraction Board`
  - bottom-left `Crew Deck`
  - bottom-right `Boat Plate`
  - centered short-lived event callouts for impacts and run events
- Tightened the wording in the run objective and onboarding text so it reads more like actionable crew direction and less like debug/tutorial copy.
- Added HUD event callouts for:
  - impacts
  - brace mitigation
  - chunk loss
  - cargo washed overboard
  - rescue/cache completion
  - extraction success
  - run failure
- Verified:
  - clean parse smoke with `godot --headless --path . --quit-after 2`
  - local GUI autorun capture at `/tmp/builtaboat-run-hud-pass.png`
  - refined local GUI autorun capture at `/tmp/builtaboat-run-hud-pass-v2.png`
- The second capture confirms the new run HUD hierarchy reads cleanly, though the gameplay camera still keeps the boat smaller in frame than ideal and can be tuned separately from the HUD.

## 2026-03-08 Hangar Avatar Chase Camera

- Wrote the short design note to `docs/plans/2026-03-08-hangar-avatar-chase-camera-design.md`.
- Replaced the hangar camera blend-to-boat behavior with a pure third-person avatar chase camera in `scenes/hangar/hangar.gd`.
- The hangar camera now:
  - follows the local avatar position and facing directly
  - keeps a simple over-the-shoulder offset
  - preserves the existing reaction jolt
  - no longer recenters itself around the shared boat while walking
- Tightened the hangar camera follow response so movement feels less like a scene camera and more like a builder avatar camera.
- Verified:
  - clean parse smoke with `godot --headless --path . --quit-after 2`
  - local hangar capture with `--autohangar-role=bumper_left` at `/tmp/builtaboat-hangar-chase.png`
- The hangar capture confirms the camera is now sitting behind the avatar instead of sticking to the shared boat framing.

## 2026-03-08 Third-Person Avatar Control Refactor Design

- Approved the full control-model refactor toward one Fortnite-style third-person avatar system across hangar and run.
- Locked the new control rules:
  - crosshair-centered camera
  - avatar always faces aim yaw
  - free deck movement during runs
  - soft helm interaction zone
  - brace usable anywhere on the boat
  - repair as a proximity action near damaged sections
  - real overboard state with active recovery
- Wrote the approved design doc to `docs/plans/2026-03-08-third-person-avatar-control-refactor-design.md`.
- Wrote the fallback implementation plan to `docs/plans/2026-03-08-third-person-avatar-control-refactor-implementation-plan.md` because the `writing-plans` skill is not available in this session.

## 2026-03-08 Run Deck Avatar Foundation

- Implemented the first real run-avatar layer for Milestone 2 in `autoload/network_runtime.gd` and `scenes/run_client/run_client.gd`.
- Added replicated `run_avatar_state` snapshots to the authoritative runtime so clients can sync deck-local avatar position, velocity, and facing while the boat moves underneath them.
- Replaced the old placeholder crew update path so run-side crew visuals now read from replicated deck-avatar state, while currently claimed stations still snap avatars to their existing station positions until the soft-zone interaction refactor lands.
- Switched the run camera to a player-follow chase camera with mouse-look and crosshair-facing foundations.
- Kept the current station-driven extraction loop intact for safety:
  - helm / brace / grapple / repair still use the old interaction logic for now
  - movement currently matters most while a player is not occupying a station
- Verified:
  - clean parse smoke with `godot --headless --path . --quit-after 2`
  - full local `hangar -> run` autorun capture at `/tmp/builtaboat-run-deck-avatar.png`
- The autorun still completes the existing extraction path under the new deck-avatar runtime, but true free-moving station use is intentionally deferred to the next interaction-refactor milestone.

## 2026-03-08 Run Interaction Refactor

- Implemented Milestone 3 of the avatar-control refactor in `autoload/network_runtime.gd` and `scenes/run_client/run_client.gd`.
- Changed the authoritative run interaction rules so:
  - `helm` is now a soft station zone with range validation and auto-release if the helmsman drifts too far away
  - `grapple` remains the anchored crane station for now
  - `brace` can be triggered from anywhere on the boat
  - `repair` now spends shared patch kits only when a crewmate is physically close to damaged hull blocks
- Updated the run client so the local avatar stays free while holding helm control, while grapple still anchors the avatar to the crane.
- Narrowed station cycling to the claimable deck jobs only:
  - `helm`
  - `grapple`
- Updated the run HUD and onboarding copy so it now teaches:
  - brace anywhere
  - patch nearby hull
  - move close to helm before claiming it
  - drift too far from helm and steering control drops
- Updated headless autorun helpers so bots can walk to helm or grapple, release anchored grapple control, and move toward damaged hull sections before attempting repairs.
- Verified:
  - clean parse smoke with `godot --headless --path . --quit-after 2`
  - a fresh single-client run smoke on port `7166` reached the new `helm -> grapple -> helm` handoff flow, completed loot recovery, rescue, and cache steps, and stayed alive under the new control model
  - a targeted repair smoke on port `7167` showed `RepairBot patched the hull` four times, reducing breaches and consuming patch kits from deck proximity instead of a repair station
- The current open gap is that the single-client autorun demo still does not finish a full extraction before the auto-quit timeout after this refactor, so the new control flow is verified mid-run but not yet re-signed-off end-to-end to hangar.

## 2026-03-08 Run Controller Hardening

- Tightened the refactored run client in `scenes/run_client/run_client.gd` so the new `brace anywhere` rule is used consistently by the autorun helmsman instead of only during salvage timing.
- Added a shared `_maybe_request_autobrace()` helper and wired it into:
  - scripted helm autopilot
  - the single-client autorun demo
  - the coordinated driver roles used for multiplayer smokes
- Tightened the coordinated return route so the helmsman no longer stalls at the mid-lane staging point after rescue/cache recovery when the deck-avatar controller is using the new soft-station flow.
- Verified:
  - clean parse smoke with `godot --headless --path . --quit-after 2`
  - a fresh end-to-end extraction regression on seed `9191` with a temporary Godot `HOME`
  - the refactored deck-avatar run now reaches `phase=success`, secures `2` cargo, banks `118 gold / 6 salvage`, and returns cleanly to the hangar
- Added the longer-window regression command to `README.md` so the avatar-controller path can be re-run without rediscovering the new timeout budget.

## 2026-03-08 Overboard And Active Recovery

- Implemented the next avatar-controller milestone in `autoload/network_runtime.gd`, `autoload/game_config.gd`, and `scenes/run_client/run_client.gd`.
- Added a server-authoritative overboard state to the run avatar model:
  - players can now be knocked off the deck by strong unbraced impacts near the rail
  - overboard players lose station access and boat-control actions until they recover
  - the server validates both overboard transitions and climb-back recovery
- Added active recovery support:
  - overboard players enter a limited swim state around the boat
  - ladder and stern-line recovery markers are exposed as valid climb-back points
  - pressing `F` near a recovery target climbs the player back onto the deck
- Updated the run client controller and HUD so:
  - camera and movement switch cleanly between deck motion and swim motion
  - overboard players get dedicated objective/onboarding guidance
  - crew visuals and event callouts now show overboard and recovery state clearly
- Added a hidden `--autoforce-overboard` smoke flag in `autoload/game_config.gd` so automated tests can deterministically force the new recovery path without depending on a lucky collision.
- Verified:
  - clean parse smoke with `godot --headless --path . --quit-after 2`
  - deterministic overboard recovery regression on port `7176`
  - server log confirmed the full loop:
    - `OverboardBot went overboard.`
    - `OverboardBot climbed back aboard via the Stern Line.`
  - the run remained live after recovery, proving the boat and crew state did not soft-lock after the overboard transition.

## 2026-03-08 Social Builder Completion Pass

- Implemented the next hangar milestone in `autoload/network_runtime.gd`, `scenes/hangar/hangar.gd`, and `scenes/hangar/hangar_hud.tscn`.
- Extended the authoritative `hangar_avatar_state` snapshot so every builder now replicates:
  - selected block id
  - rotation steps
  - target cell
  - remove cell
  - whether a target is active
  - placement feedback state
- Kept the existing authoritative builder edit model intact:
  - place/remove rules are unchanged
  - the new snapshot is visual-only builder presence, not a lock or reservation mechanic
- Updated the hangar scene so remote builders now show:
  - avatar
  - nameplate with current build intent
  - tool color matching the selected block
  - a translucent target ghost and ring at the teammate's active build cell
- Tightened the local hangar readability pass:
  - shorter target wording
  - clearer `Ready / Occupied / Move Closer / Outside Volume` feedback hierarchy
  - more compact selection and controls text
  - roster lines that include each crewmate's current build intent
  - lighter HUD framing so the boat remains the hero
- Hardened the run client while verifying the milestone:
  - autorun now recovers if the demo bot goes overboard mid-run
  - overboard crew visuals no longer try to set global transforms before entering the tree
- Verified:
  - clean parse smoke with `godot --headless --path . --quit-after 2`
  - dedicated-server two-client hangar capture at `/tmp/builtaboat-social-builder-dedicated-v2.png`
  - the capture shows `VisualHost` plus `BuilderBuddy` with shared build presence and the tighter hangar HUD
  - fresh end-to-end extraction regression on seed `9191` still returned to hangar and banked `118 gold / 6 salvage` after an overboard recovery during the run

## TODOs

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
- Treat the hangar as a social third-person builder baseline now, and keep future polish focused on readability rather than replacing the control model again.

## 2026-03-09 - Inventory system and tool HUD pass

- Added shared toolbelt definitions in `autoload/network_runtime.gd` for both phases:
  - hangar: `Build`, `Remove`, `Yard`
  - run: `Helm`, `Brace`, `Grapple`, `Repair`, `Recover`
- Added a real shared run cargo manifest in `run_state`:
  - wreck salvage now appends to `cargo_manifest`
  - cargo lost from chunk loss trims the manifest instead of only changing the count
  - successful extraction snapshots the secured manifest for the results/UI path
- Added inventory snapshot helpers in `autoload/network_runtime.gd`:
  - hangar inventory now summarizes dock totals, unlocked parts, mounted blueprint parts, and the next yard purchase
  - run inventory now summarizes cargo aboard, patch kits, support bonuses, and cargo lost to sea
- Updated the hangar HUD:
  - new bottom-center `Build Tools` belt
  - new toggleable `Shared Inventory` panel
  - `1 / 2 / 3` selects builder tools
  - `F` now uses the active builder tool while the older direct shortcuts still work
- Updated the run HUD:
  - new bottom-center `Tool Belt`
  - new toggleable `Ship Inventory` panel
  - `1 / 2 / 3 / 4 / 5` selects run tools
  - `F` now acts contextually for `Brace` and `Repair`, while still claiming/releasing stations for `Helm` and `Grapple`
- Verified:
  - clean parse smoke with `godot --headless --path . --quit-after 2`
  - fresh temp-`HOME` end-to-end autohost regression on port `7195`
  - the run still completed `hangar -> run -> extraction -> hangar`
  - the server banked `82 gold / 5 salvage` on return with the new inventory/toolbelt code active

## 2026-03-09 - Personal toolbelt inventory follow-up

- Extended the inventory snapshots so the local character's carried toolbelt is part of inventory data, not just the HUD strip
- Hangar inventory now shows an `On You` section for `Build`, `Remove`, and `Yard`, with the equipped tool marked
- Run inventory now shows an `On You` section for `Helm`, `Brace`, `Grapple`, `Repair`, and `Recover`, with the equipped tool marked
- Verified with a fresh parse smoke: `godot --headless --path . --quit-after 2`
