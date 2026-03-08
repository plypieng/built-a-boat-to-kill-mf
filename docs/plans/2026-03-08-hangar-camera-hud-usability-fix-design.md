# Hangar Camera And HUD Usability Fix

Date: 2026-03-08

## Problem

Local testing in the Godot editor exposed two immediate usability problems in the hangar:

- the hangar camera does not reliably feel like the active follow camera for the local avatar
- the current hangar UI reads like a large debug menu and covers too much of the build space

Together, these make the hangar feel more like a tool screen than a playful shared builder.

## Goal

Make the hangar immediately playable for local editor testing by:

- explicitly activating the hangar camera
- tightening the follow-camera presentation around the local avatar and boat
- replacing the full-height side-panel presentation with a lighter overlay
- keeping important builder information available without blocking the center of the screen

## Chosen Approach

Use a compact overlay pass rather than a full redesign.

This means:

- make the hangar `Camera3D` current when the scene is ready
- keep the current data model and labels, but reorganize them into smaller anchored panels
- surface only the most important build information by default
- move secondary details into a collapsible section instead of always showing them

## Scope

In scope:

- explicit camera activation
- smaller hangar HUD panels
- clearer top-level launch/build/store status
- a detail toggle for secondary information

Out of scope:

- changing hangar gameplay
- changing the run HUD
- reworking the boot/connect flow
- deeper art polish

## Verification

The fix is successful if:

- the local editor run enters the hangar with the avatar-follow camera active
- the center of the screen stays readable for building
- the user can still see build, warning, progression, and launch information
- the hangar feels closer to gameplay and less like a debug control panel
