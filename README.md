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

## Local Run

Start the local dedicated server:

```bash
./tools/run_server.sh --port=7000 --seed=424242
```

Start a client:

```bash
./tools/run_client.sh
```

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

## Notes

- The current client scene renders a simple ocean and replicated shared-boat placeholder.
- The current server scene logs heartbeat, roster, helm ownership, and boat state.
- Manual desktop testing still matters for feel and control tuning even though the headless handshake and movement loop are now scriptable.
