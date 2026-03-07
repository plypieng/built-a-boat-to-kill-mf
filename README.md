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

## Local Run

Start the local dedicated server:

```bash
./tools/run_server.sh --port=7000 --seed=424242
```

Start a client:

```bash
./tools/run_client.sh
```

The client now lands in the shared hangar builder after connecting. Build the crew boat there, then press `Launch Run`.

Optional client overrides:

```bash
./tools/run_client.sh --host=127.0.0.1 --port=7000 --name=Captain
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
godot --headless --path . --quit-after 260 -- --host=127.0.0.1 --port=7000 --name=BuilderA --autoconnect --autobuild-role=builder_a --quit-after-connect-ms=2600
```

Two-client live co-build smoke test:

```bash
godot --headless --path . --quit-after 260 -- --host=127.0.0.1 --port=7000 --name=BuilderA --autoconnect --autobuild-role=builder_a --quit-after-connect-ms=2600
godot --headless --path . --quit-after 260 -- --host=127.0.0.1 --port=7000 --name=BuilderB --autoconnect --autobuild-role=builder_b --quit-after-connect-ms=2600
```

Headless hangar-to-run handoff smoke test:

```bash
godot --headless --path . --quit-after 360 -- --host=127.0.0.1 --port=7000 --name=LaunchBot --autoconnect --autobuild-role=builder_launch --quit-after-connect-ms=3200
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

Headless dock handoff check:

```bash
godot --headless --path . --quit-after 4200 -- --host=127.0.0.1 --port=7000 --name=DockVerifier --autoconnect --autobuild-role=builder_launch --autorun-demo --autocontinue-to-dock
```

## Notes

- The current client scene renders a simple ocean and replicated shared-boat placeholder.
- The current client scene now renders deck stations, placeholder crew, wreck salvage, loot, extraction markers, and a result overlay.
- The current run model includes breach-driven speed loss and hull leakage that can be countered at the repair bench.
- The current autorun route and hazard layout now support a clean four-role extraction pass with no damage when the crew coordinates correctly.
- The current run result now banks local gold and salvage into the dock scene after extraction or failure.
- Repairs are limited by shared patch kits, and the resupply cache can top the team back up once per run while adding bonus rewards.
- The current connect flow now lands in a shared 3D hangar builder where the crew can edit one live blueprint together before launching.
- The current shared builder allows disconnected chunks, warns about them, and derives run stats from the main connected chunk.
- The current server scene logs heartbeat, roster, station ownership, cargo, repairs, breach state, extraction progress, and run outcomes.
- Manual desktop testing still matters for feel and control tuning even though the headless handshake and movement loop are now scriptable.
