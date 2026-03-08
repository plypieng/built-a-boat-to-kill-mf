# Hangar Avatar Chase Camera Design

## Context

The hangar camera currently blends toward the boat/build focus, which makes local movement feel like the camera is stuck to the hangar instead of following the player avatar.

## Decision

Switch the hangar to a pure avatar chase camera.

## Design

- The local hangar camera always belongs to the local avatar.
- The camera anchor is derived only from the avatar position and facing, not from the boat span or build focus.
- The camera keeps a simple third-person over-the-shoulder offset behind the avatar.
- The existing reaction jolt stays active so impacts still read.
- Build targeting remains camera-crosshair based.

## Expected Result

- `WASD` movement should feel Roblox-like in the hangar.
- The player should feel like they are moving through the hangar, not rotating around a fixed scene camera.
- Building still uses the same crosshair placement model.
