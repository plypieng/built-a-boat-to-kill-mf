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

- a repair bench station for in-run hull recovery
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

The client now lands in the shared hangar builder after connecting. Use `W A S D` and `Space` to move, aim the center crosshair, use `Q / E` to cycle blocks, `R` to rotate, `F` to place, `X` to remove, `Z / C` to browse unlocks, `V` to buy the selected part, then press `Launch Run`.

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
godot --headless --path . --quit-after 2200 -- --host=127.0.0.1 --port=7000 --name=BraceBot --autoconnect --autoclaim-station=brace --autobrace --autobrace-distance=8.0 --quit-after-connect-ms=10000
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

## Notes

- For deterministic smoke tests, start the server and all clients with the same temporary `HOME` so the shared boat blueprint starts from a clean save.
- `--autobuild-role` is now a one-shot per client process, so `--autocontinue-to-dock` returns cleanly to hangar instead of immediately relaunching the run.
- The current client scene renders a simple ocean and the launched block-built boat instead of a placeholder-only hull.
- The current client scene now renders deck stations, placeholder crew, wreck salvage, loot, extraction markers, and a result overlay.
- The current run model includes breach-driven speed loss and hull leakage that can be countered at the repair bench.
- The current autorun route and hazard layout now support a clean four-role extraction pass with no damage when the crew coordinates correctly.
- The current run result now banks shared gold and salvage into the host/server profile after extraction or failure, and the hangar store spends from that shared pool.
- Repairs are limited by shared patch kits, and the resupply cache can top the team back up once per run while adding bonus rewards.
- The current connect flow now lands in a shared 3D hangar builder where the crew can edit one live blueprint together before launching.
- The current hangar now uses a short-range camera-crosshair build ghost tied to the third-person builder avatar, so moving around the boat matters while building.
- The current shared-builder autobuild helpers now reposition the hangar avatar before placing or removing blocks so automated smoke tests obey the same range rule as manual builders.
- The current hangar now shows a clearer build-tool panel, placement-state feedback, and launch-readiness summary so the crew can read the boat status faster before launching.
- The current hangar also shows an unlock yard with shared team totals, selected-part descriptions, and immediate palette updates after server-approved purchases.
- The current hangar and run scenes now include lightweight contextual onboarding text so first-time players can understand building, rescue pressure, squalls, and extraction without live coaching.
- The current hangar presentation now frames the shared boat more deliberately with an over-shoulder camera, lighter dock dressing, and simplified crew roster text.
- The current hangar now supports hard builder-to-builder bump reactions, and the new `--autohangar-role=bumper_left|bumper_right` helpers give a repeatable smoke path for that behavior.
- The current shared builder allows disconnected chunks, warns about them, and derives run stats from the main connected chunk.
- The current runtime damage model is per-block for HP and chunk detachment, while buoyancy and handling still derive from aggregate stats on the surviving main chunk.
- The current reaction system is a lightweight non-ragdoll layer: hard hangar bumps and run impacts briefly interrupt control, add knockback/camera jolt, and let brace reduce the severity of run-side reactions.
- The current Week 3 run layer procedurally seeds one optional distress rescue and one or two squall bands from the run seed, so route choice and timing change between seeds without abandoning the extraction-loop structure.
- The current networking model now sends boat motion separately from structural runtime state so large block boats do not overflow the unreliable ENet packet budget during launch.
- Disconnect cleanup now coalesces network state flushes for a short window so quick multi-client hangar teardowns do not re-trigger the old ENet send error.
- The current server scene logs heartbeat, progression totals, roster, station ownership, cargo, repairs, breach state, extraction progress, and run outcomes.
- `--capture-frame-path` and `--capture-frame-delay-ms` let the hangar and run client save a viewport PNG for local visual inspections without relying on OS-level window capture.
- A manual visual pass confirmed the post-run reward handoff, but also showed that the hangar boat reads too small beneath the current UI and the in-run nameplates/station labels are overcrowded once multiple crew stand on deck.
