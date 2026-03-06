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

## Notes

- The current client scene is intentionally a placeholder ocean view that proves the connection/bootstrap flow.
- The current server scene logs heartbeat and peer roster updates.
- Future Milestone 1 work should replace the placeholder run view with a replicated shared boat prototype.
