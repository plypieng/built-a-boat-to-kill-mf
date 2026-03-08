# BuiltaBoat

Desktop-first Godot prototype for a co-op ocean extraction game.

## Current State

Milestone 0 scaffolds:

- a Godot 4 project file
- autoload config and networking helpers
- a boot router that selects client or headless server mode
- a local client connection screen
- a headless dedicated-server bootstrap scene
- placeholder run scenes for client and server
- helper scripts for running the client and local server

Milestone 1 prototype adds:

- one shared authoritative boat on the server
- explicit helm claiming
- replicated boat transform, heading, speed, and driver state
- local keyboard controls plus headless autodrive flags for smoke tests
- on-deck crew placeholder visuals with helm highlighting
- replicated hazard props and a server-authoritative brace/collision loop

Milestone 2 prototype adds:

- explicit on-deck helm, brace, and grapple stations with ownership and station cycling
- a grapple loot target that feeds shared cargo
- an extraction buoy with authoritative progress and completion rules
- a success/failure result overlay in the client scene
- a scripted autorun demo for end-to-end success-path smoke tests

Milestone 3 prototype adds:

- shared patch-kit repairs that recover hull once a crewmate reaches the damaged section
- a wreck salvage POI with multiple pickups instead of a single floating crate
- hull breaches that reduce top speed and leak integrity over time until repaired
- role-based autorun helpers for `driver`, `grapple`, `brace`, and `repair`
- a tuned return route plus hazard layout that support a clean four-role extraction pass

Milestone 4 prototype adds:

- improved manual-play readability with a clearer objective HUD, dock resource readout, and a more forgiving chase camera
- a local dock/hangar scene that receives players after a run and banks extracted rewards
- reward payout fields on the authoritative run state, including gold and salvage totals
- a limited patch-kit repair economy instead of infinite free repairs
- an optional resupply cache encounter that grants a bonus reward package and one extra patch kit

Milestone A shared builder foundation adds:

- a shared authoritative team boat blueprint on the dedicated server
- a live co-op 3D hangar builder with true 3D grid placement, remove, and 90-degree rotation
- permissive disconnected builds plus seaworthiness warnings before launch
- derived boat stats from the built boat, including hull strength, top speed, cargo capacity, and repair kits
- hangar-to-run scene routing so the current extraction loop launches from the shared builder instead of a post-run dock stub

Milestone B runtime block damage adds:

- launched boats now render their actual block-built runtime layout in the run scene
- disconnected launch chunks sink immediately at run start instead of silently inflating stats
- collisions and unbraced salvage backlash now damage a small local cluster of runtime blocks
- destroyed blocks can split off attached chunks, which sink and immediately remove their thrust, cargo, repair, and hull contribution
- runtime boat sync is now split so the fast boat-state packet stays lean while structural damage replicates as its own reliable snapshot

Milestone C social builder avatars adds:

- a third-person hangar avatar for the local player with walk, jump, gravity, and dock collision
- a local follow camera so the hangar starts feeling like a shared build space instead of a static editor view
- solid collision on placed boat blocks so the hangar boat is becoming a walkable shared object
- replicated hangar avatar state for connected builders
- a short-range camera-crosshair build ghost that snaps against the boat and dock in front of the crew
- authoritative hangar build-range validation so edits now depend on where the builder avatar is standing

Week 2 reward loop adds:

- a shared host/server progression snapshot that tracks team gold, salvage, unlocks, and the latest unlock result
- a compact hangar unlock yard with three new prototype parts:
  - `reinforced_hull`
  - `twin_engine`
  - `stabilizer`
- server-validated unlock purchases that immediately update the live shared builder palette
- shared progression persistence so restarting the server reloads the unlocked parts and upgraded blueprint

## Local Run

Start the local dedicated server:

```bash
./tools/run_server.sh --port=7000 --seed=424242
```

Start a client:

```bash
./tools/run_client.sh
```

The client now lands in the shared hangar builder after connecting. Use `W A S D` and `Space` to move, aim the center crosshair, use `1 / 2 / 3` to switch between `Build`, `Remove`, and `Yard`, `Q / E` to cycle blocks, `R` to rotate, `F` to use the active builder tool, `X` to remove, `Z / C` to browse unlocks, `V` to buy the selected part, `I` to open the shared inventory panel, `Tab` or `H` to toggle the detailed hangar overlay, then press `Launch Run`.

In runs, use mouse aim plus `W A S D` to move on deck or swim in the sea, `1 / 2 / 3 / 4 / 5` to switch between `Helm`, `Brace`, `Grapple`, `Repair`, and `Recover`, `Q / E` to cycle the claimable stations, `F` to use the active tool or claim/release the selected station, `Space` to brace from anywhere on the boat, `G` to fire the grapple while on the crane, `R` to patch nearby damaged hull when you are close enough, and `I` to open the ship inventory panel. If you get knocked overboard, swim to a ladder or stern line marker and press `F` to climb back aboard.

Optional client overrides:

```bash
./tools/run_client.sh --host=127.0.0.1 --port=7000 --name=Captain
```

Desktop frame capture for visual checks:

```bash
./tools/run_client.sh --host=127.0.0.1 --port=7000 --name=VisualCheck --autoconnect --capture-frame-path=/tmp/builtaboat-frame.png --capture-frame-delay-ms=1800 --quit-after-connect-ms=3200
```

Headless smoke-test client:

```bash
godot --headless --path . --quit-after 300 -- --host=127.0.0.1 --port=7000 --name=Verifier --autoconnect --quit-after-connect-ms=1000
```

Headless movement smoke test:

```bash
godot --headless --path . --quit-after 400 -- --host=127.0.0.1 --port=7000 --name=DriverBot --autoconnect --autodrive-ms=1800 --autodrive-throttle=1.0 --autodrive-steer=0.2 --quit-after-connect-ms=2600
```

Headless brace comparison:

```bash
godot --headless --path . --quit-after 400 -- --host=127.0.0.1 --port=7000 --name=BraceBot --autoconnect --autodrive-ms=1800 --autodrive-throttle=1.0 --autodrive-steer=0.0 --autobrace --autobrace-distance=8.0 --quit-after-connect-ms=2600
```

Two-client crew sync smoke test:

```bash
godot --headless --path . --quit-after 450 -- --host=127.0.0.1 --port=7000 --name=DriverBot --autoconnect --autodrive-ms=1600 --autodrive-throttle=1.0 --autodrive-steer=0.15 --autobrace --autobrace-distance=8.0 --quit-after-connect-ms=2600
godot --headless --path . --quit-after 450 -- --host=127.0.0.1 --port=7000 --name=Deckhand --autoconnect --quit-after-connect-ms=2600
```

Headless shared-builder smoke test:

```bash
godot --headless --path . --quit-after 420 -- --host=127.0.0.1 --port=7000 --name=BuilderA --autoconnect --autobuild-role=builder_a --quit-after-connect-ms=4200
```

Two-client live co-build smoke test:

```bash
godot --headless --path . --quit-after 420 -- --host=127.0.0.1 --port=7000 --name=BuilderA --autoconnect --autobuild-role=builder_a --quit-after-connect-ms=4200
godot --headless --path . --quit-after 420 -- --host=127.0.0.1 --port=7000 --name=BuilderB --autoconnect --autobuild-role=builder_b --quit-after-connect-ms=4200
```

Headless hangar-to-run handoff smoke test:

```bash
godot --headless --path . --quit-after 360 -- --host=127.0.0.1 --port=7000 --name=LaunchBot --autoconnect --autobuild-role=builder_launch --quit-after-connect-ms=3200
```

Launch-time loose chunk sinking smoke test:

```bash
godot --headless --path . --quit-after 420 -- --host=127.0.0.1 --port=7000 --name=LooseLaunch --autoconnect --autobuild-role=builder_loose_launch --quit-after-connect-ms=4200
```

Headless first-run-loop success demo:

```bash
godot --headless --path . --quit-after 1600 -- --host=127.0.0.1 --port=7000 --name=DemoCaptain --autoconnect --autobuild-role=builder_launch --autorun-demo --quit-after-connect-ms=12000
```

Headless failure-path crash test:

```bash
godot --headless --path . --quit-after 3000 -- --host=127.0.0.1 --port=7000 --name=CrashBot --autoconnect --autobuild-role=builder_launch --autoclaim-station=helm --autodrive-ms=22000 --autodrive-throttle=1.0 --autodrive-steer=0.0 --quit-after-connect-ms=23000
```

Three-client co-op salvage smoke test:

```bash
godot --headless --path . --quit-after 2200 -- --host=127.0.0.1 --port=7000 --name=DriverBot --autoconnect --autobuild-role=builder_launch --autorun-role=driver --quit-after-connect-ms=17000
godot --headless --path . --quit-after 2200 -- --host=127.0.0.1 --port=7000 --name=GrapplerBot --autoconnect --autorun-role=grapple --quit-after-connect-ms=17000
godot --headless --path . --quit-after 2200 -- --host=127.0.0.1 --port=7000 --name=BraceBot --autoconnect --autorun-role=brace --quit-after-connect-ms=17000
```

Two-client repair-pressure soak test:

```bash
godot --headless --path . --quit-after 2600 -- --host=127.0.0.1 --port=7000 --name=CrashBot --autoconnect --autobuild-role=builder_launch --autoclaim-station=helm --autodrive-ms=20000 --autodrive-throttle=1.0 --autodrive-steer=0.0 --quit-after-connect-ms=21000
godot --headless --path . --quit-after 2600 -- --host=127.0.0.1 --port=7000 --name=RepairBot --autoconnect --autorun-role=repair --quit-after-connect-ms=21000
```

Four-client coordinated clean extraction smoke test:

```bash
godot --headless --path . --quit-after 2600 -- --host=127.0.0.1 --port=7000 --name=DriverBot --autoconnect --autobuild-role=builder_launch --autorun-role=driver --quit-after-connect-ms=20000
godot --headless --path . --quit-after 2600 -- --host=127.0.0.1 --port=7000 --name=GrapplerBot --autoconnect --autorun-role=grapple --quit-after-connect-ms=20000
godot --headless --path . --quit-after 2600 -- --host=127.0.0.1 --port=7000 --name=BraceBot --autoconnect --autorun-role=brace --quit-after-connect-ms=20000
godot --headless --path . --quit-after 2600 -- --host=127.0.0.1 --port=7000 --name=RepairBot --autoconnect --autorun-role=repair --quit-after-connect-ms=20000
```

Runtime chunk-detach and cargo-loss smoke test:

```bash
godot --headless --path . --quit-after 2200 -- --host=127.0.0.1 --port=7000 --name=DetachDriver --autoconnect --autobuild-role=builder_fragile_cargo --autorun-role=driver_detach_test --quit-after-connect-ms=18000
godot --headless --path . --quit-after 2200 -- --host=127.0.0.1 --port=7000 --name=GrapplerBot --autoconnect --autorun-role=grapple --quit-after-connect-ms=18000
godot --headless --path . --quit-after 2200 -- --host=127.0.0.1 --port=7000 --name=BraceBot --autoconnect --autorun-role=brace --quit-after-connect-ms=18000
```

Hangar hard-bump reaction smoke test:

```bash
godot --headless --path . --quit-after 600 -- --host=127.0.0.1 --port=7000 --name=BumperLeft --autoconnect --autohangar-role=bumper_left --quit-after-connect-ms=4200
godot --headless --path . --quit-after 600 -- --host=127.0.0.1 --port=7000 --name=BumperRight --autoconnect --autohangar-role=bumper_right --quit-after-connect-ms=4200
```

Run-side braced impact comparison:

```bash
godot --headless --path . --quit-after 2200 -- --host=127.0.0.1 --port=7000 --name=DriverBot --autoconnect --autobuild-role=builder_launch --autoclaim-station=helm --autodrive-ms=9000 --autodrive-throttle=1.0 --autodrive-steer=0.0 --quit-after-connect-ms=10000
godot --headless --path . --quit-after 2200 -- --host=127.0.0.1 --port=7000 --name=BraceBot --autoconnect --autorun-role=brace --autobrace --autobrace-distance=8.0 --quit-after-connect-ms=10000
```

Run-side proximity repair smoke:

```bash
godot --headless --path . --quit-after 5000 -- --host=127.0.0.1 --port=7000 --name=CrashBot --autoconnect --autobuild-role=builder_launch --autoclaim-station=helm --autodrive-ms=18000 --autodrive-throttle=1.0 --autodrive-steer=0.0 --quit-after-connect-ms=19000
godot --headless --path . --quit-after 5000 -- --host=127.0.0.1 --port=7000 --name=RepairBot --autoconnect --autorun-role=repair --quit-after-connect-ms=19000
```

Headless dock handoff check:

```bash
godot --headless --path . --quit-after 4200 -- --host=127.0.0.1 --port=7000 --name=DockVerifier --autoconnect --autobuild-role=builder_launch --autorun-demo --autocontinue-to-dock
```

Week 2 unlock-loop smoke sequence:

```bash
TEST_HOME="$(mktemp -d /tmp/builtaboat-week2-XXXXXX)"
HOME="$TEST_HOME" ./tools/run_server.sh --port=7000 --seed=424242
HOME="$TEST_HOME" godot --headless --path . --quit-after 6000 -- --host=127.0.0.1 --port=7000 --name=RewardBot --autoconnect --autobuild-role=builder_launch --autorun-demo --autocontinue-to-dock --quit-after-connect-ms=24000
HOME="$TEST_HOME" godot --headless --path . --quit-after 900 -- --host=127.0.0.1 --port=7000 --name=UnlockBot --autoconnect --autobuild-role=builder_unlock_reinforced_hull --quit-after-connect-ms=4200
```

Week 3 procedural rescue + squall smoke sequence:

```bash
TEST_HOME="$(mktemp -d /tmp/builtaboat-week3-XXXXXX)"
HOME="$TEST_HOME" ./tools/run_server.sh --port=7000 --seed=101
HOME="$TEST_HOME" godot --headless --path . --quit-after 6000 -- --host=127.0.0.1 --port=7000 --name=Week3Bot --autoconnect --autobuild-role=builder_launch --autorun-demo --autocontinue-to-dock --quit-after-connect-ms=28000
```

Week 3 layout-variation spot check:

```bash
TEST_HOME="$(mktemp -d /tmp/builtaboat-week3-layout-XXXXXX)"
HOME="$TEST_HOME" ./tools/run_server.sh --port=7000 --seed=404
HOME="$TEST_HOME" godot --headless --path . --quit-after 4000 -- --host=127.0.0.1 --port=7000 --name=LayoutBot --autoconnect --autobuild-role=builder_launch --autorun-demo --quit-after-connect-ms=14000
```

Week 4 local host-flow smoke:

```bash
TEST_HOME="$(mktemp -d /tmp/builtaboat-week4-host-XXXXXX)"
HOME="$TEST_HOME" godot --headless --path . --quit-after 1200 -- --name=HostBot --port=7170 --autohost --quit-after-connect-ms=9000
```

Week 4 full local host-flow loop:

```bash
TEST_HOME="$(mktemp -d /tmp/builtaboat-week4-full-XXXXXX)"
HOME="$TEST_HOME" godot --headless --path . --quit-after 7000 -- --name=Week4Host --port=7172 --autohost --autobuild-role=builder_launch --autorun-demo --autocontinue-to-dock --quit-after-connect-ms=28000
```

Avatar-controller end-to-end extraction regression:

```bash
TEST_HOME="$(mktemp -d /tmp/builtaboat-avatar-e2e-XXXXXX)"
HOME="$TEST_HOME" ./tools/run_server.sh --port=7171 --seed=9191
HOME="$TEST_HOME" godot --headless --path . --quit-after 12000 -- --host=127.0.0.1 --port=7171 --name=Week4Bot --autoconnect --autobuild-role=builder_launch --autorun-demo --autocontinue-to-dock --quit-after-connect-ms=52000
```

Overboard recovery regression:

```bash
TEST_HOME="$(mktemp -d /tmp/builtaboat-overboard-clean-XXXXXX)"
HOME="$TEST_HOME" ./tools/run_server.sh --port=7176 --seed=424242
HOME="$TEST_HOME" godot --headless --path . --quit-after 7000 -- --host=127.0.0.1 --port=7176 --name=CrashDriver --autoconnect --autobuild-role=builder_launch --autoclaim-station=helm --autodrive-ms=12000 --autodrive-throttle=1.0 --autodrive-steer=0.0 --quit-after-connect-ms=18000
HOME="$TEST_HOME" godot --headless --path . --quit-after 7000 -- --host=127.0.0.1 --port=7176 --name=OverboardBot --autoconnect --autorun-role=overboard_recovery --autoforce-overboard --quit-after-connect-ms=18000
```

Windows client export:

```bash
godot --headless --path . --export-release "Windows Client" build/windows-client/BuiltaBoat.exe
```

Windows dedicated-server export:

```bash
godot --headless --path . --export-release "Windows Dedicated Server" build/windows-server/BuiltaBoatServer.exe
```

Windows playtest bundle helper:

```bash
bash tools/package_windows_playtest.sh \
  build/windows-client/BuiltaBoat.exe \
  build/windows-server/BuiltaBoatServer.exe \
  dist/windows-playtest
```

## Notes

- For deterministic smoke tests, start the server and all clients with the same temporary `HOME` so the shared boat blueprint starts from a clean save.
- `--autobuild-role` is now a one-shot per client process, so `--autocontinue-to-dock` returns cleanly to hangar instead of immediately relaunching the run.
- The current client scene renders a simple ocean and the launched block-built boat instead of a placeholder-only hull.
- The current client scene now renders deck stations, placeholder crew, wreck salvage, loot, extraction markers, and a result overlay.
- The current run model includes breach-driven speed loss and hull leakage that can be countered by carrying patch kits to the damaged section and repairing it in person.
- The current autorun route and hazard layout now support a clean four-role extraction pass with no damage when the crew coordinates correctly.
- The current run result now banks shared gold and salvage into the host/server profile after extraction or failure, and the hangar store spends from that shared pool.
- Repairs are limited by shared patch kits, and the resupply cache can top the team back up once per run while adding bonus rewards.
- The current connect flow now lands in a shared 3D hangar builder where the crew can edit one live blueprint together before launching.
- The current connect flow now supports `Host Game` and `Join By IP`, with host mode launching a local authoritative server process before connecting the client to `127.0.0.1`.
- The current hangar now uses a short-range camera-crosshair build ghost tied to the third-person builder avatar, so moving around the boat matters while building.
- The current authoritative `hangar_avatar_state` now carries each builder's selected part, rotation, target cell, and placement state so teammates render from the same shared build-intent snapshot.
- The current shared-builder autobuild helpers now reposition the hangar avatar before placing or removing blocks so automated smoke tests obey the same range rule as manual builders.
- The current hangar now shows a clearer build-tool panel, placement-state feedback, and launch-readiness summary so the crew can read the boat status faster before launching.
- The current hangar now renders remote builders with colored tool cues, a translucent target ghost, and a tighter crew roster so co-build coordination is easier without voice callouts.
- The current hangar also shows an unlock yard with shared team totals, selected-part descriptions, and immediate palette updates after server-approved purchases.
- The current hangar and run scenes now include lightweight contextual onboarding text so first-time players can understand building, rescue pressure, squalls, and extraction without live coaching.
- The current run scene now uses the first `Expedition Board` HUD pass: a centered objective strip, top-right extraction board, bottom-left crew deck, bottom-right boat plate, and short event callouts for impacts and run-state changes.
- The current run scene now has the first real deck-avatar layer for the control refactor: replicated crew positions on the moving boat, a player-follow chase camera, and run-side mouse-look/crosshair-facing foundations while the old station logic still handles interactions.
- The current run interaction layer now keeps only `helm` and `grapple` as claimable stations, lets crew brace from anywhere on deck, and lets repairs spend shared kits when a player is physically close to damaged hull blocks.
- Run deck traversal now projects crew onto the surviving runtime block tops instead of a fixed deck rectangle, so custom builds and detached chunks change where players can stand during a run.
- The current hangar presentation now frames the shared boat more deliberately with an over-shoulder camera, lighter dock dressing, and simplified crew roster text.
- The current hangar camera now behaves like a pure third-person avatar chase camera, so local movement follows the builder avatar instead of blending back toward the boat focus.
- The current hangar now supports hard builder-to-builder bump reactions, and the new `--autohangar-role=bumper_left|bumper_right` helpers give a repeatable smoke path for that behavior.
- The current shared builder allows disconnected chunks, warns about them, and derives run stats from the main connected chunk.
- The current runtime damage model is per-block for HP and chunk detachment, while buoyancy and handling still derive from aggregate stats on the surviving main chunk.
- The current reaction system is a lightweight non-ragdoll layer: hard hangar bumps and run impacts briefly interrupt control, add knockback/camera jolt, and let brace reduce the severity of run-side reactions.
- The current Week 3 run layer procedurally seeds one optional distress rescue and one or two squall bands from the run seed, so route choice and timing change between seeds without abandoning the extraction-loop structure.
- The current repo now includes committed Windows export presets in `export_presets.cfg`, so the client/server export commands above work once Godot `4.6.1.stable` export templates are installed locally.
- The current repo also includes `tools/package_windows_playtest.sh`, which stages separate Windows client/server export folders into a simple friend-playtest bundle with host/join batch files.
- The first real friend-test bundle was generated locally at `dist/windows-playtest`.
- The current Windows dedicated-server export runs as a GUI-subsystem `.exe`, so `HostAndPlay.bat` is the smoothest path for friends right now. `StartDedicatedServer.bat` still works, but it does not currently provide a visible console log window.
- The current networking model now sends boat motion separately from structural runtime state so large block boats do not overflow the unreliable ENet packet budget during launch.
- Disconnect cleanup now coalesces network state flushes for a short window so quick multi-client hangar teardowns do not re-trigger the old ENet send error.
- The current server scene logs heartbeat, progression totals, roster, station ownership, cargo, repairs, breach state, extraction progress, and run outcomes.
- `--capture-frame-path` and `--capture-frame-delay-ms` let the hangar and run client save a viewport PNG for local visual inspections without relying on OS-level window capture.
- A manual visual pass confirmed the post-run reward handoff, but also showed that the hangar boat reads too small beneath the current UI and the in-run nameplates/station labels are overcrowded once multiple crew stand on deck.
