# Week 4 Windows Playtest Hardening Implementation Plan

Date: 2026-03-08
Depends on: `docs/plans/2026-03-08-week-4-windows-playtest-hardening-design.md`

## Objective

Turn the current Godot prototype into a Windows-friendly friends playtest build while preserving the authoritative-server architecture.

## Note

The `writing-plans` skill was not available in this session, so this file is the direct fallback implementation plan for the approved Week 4 design.

## Delivery Principle

Reduce playtest friction without changing the game’s trust model. The server should stay authoritative while host/join, onboarding, and packaging become friend-usable.

## Scope

- improve the boot/connect flow for host and join
- make host mode easier for manual playtests
- tighten onboarding and status clarity
- prepare a Windows packaging/export path
- verify repeated-session stability for friend-style tests

## Suggested Implementation Order

1. `Boot and connect cleanup`
   - inspect the current connect flow and routing scenes
   - add clearer Host Game / Join Game controls
   - improve player name, host, and port input defaults
   - improve connection failure and missing-server messaging

2. `Host-mode usability`
   - keep the authoritative-server flow
   - add a simpler host path for local playtests
   - make it obvious what host mode does and what IP friends should use

3. `Onboarding and status polish`
   - refine prompts across connect, hangar, run, and result return
   - remove confusing or redundant status lines
   - make launch, extraction, and failure messaging clearer

4. `Windows packaging support`
   - inspect current export readiness
   - prepare client and dedicated-server export guidance or helper scripts
   - add friend-readable packaging instructions

5. `Verification`
   - host and join locally
   - verify a second client can connect
   - run success and failure loops
   - verify bad-host or missing-server messaging
   - confirm clean return to hangar and repeat-session readiness

## Expected File Touches

- `scenes/boot/client_boot.gd`
- `scenes/boot/router.gd`
- `autoload/network_runtime.gd`
- `autoload/game_config.gd`
- `README.md`
- `progress.md`
- Windows helper scripts or export-support files if needed

## Suggested Verification

- clean parse smoke
- manual or headless host flow into a local authoritative server
- local second-client join by IP/port
- full `hangar -> run -> extraction -> hangar` pass through the new entry flow
- failure-path pass through the new entry flow
- missing-server or bad-IP messaging check

## Risks

- do not accidentally convert host mode into peer-to-peer authority
- avoid packaging assumptions that only work on the current Mac dev machine
- keep Week 4 about friend usability and reliability, not new gameplay scope
- avoid overcomplicating the connect scene while trying to make it friendlier
