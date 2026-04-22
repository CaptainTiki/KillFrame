# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**NETSHIELD - Firewall Protocol** is a single-player RTS game built in Godot 4.6 with GDScript. The game features old-school RTS mechanics (harvest → build → produce units → destroy enemy core) with a stylized lowpoly 3D neon/digital aesthetic.

## Running the Project

This is a Godot 4.6 project — there are no CLI build or test commands. All development happens inside the Godot editor:

- Open `project.godot` in Godot 4.6 to launch the editor
- Press **F5** to run from the main scene (Hub menu)
- Press **F6** to run the currently open scene
- Main entry: `ui/menusystem/menus/hub/hub.tscn`
- First playable mission: `world/missions/mission01.tscn`

**Renderer:** Forward Plus, D3D12 (Windows), Jolt Physics

## Architecture

### Core Philosophy

- **Composition over inheritance** — small, focused component scripts attached to nodes, not deep class hierarchies
- **Scene-first** — build in the Godot editor and save as `.tscn`; scripts are attached to scenes, not the other way around
- **Co-location** — each actor/building folder contains both the `.tscn` and `.gd` files together

### Directory Layout

```
actors/          # Units and buildings (each subfolder has .tscn + .gd)
  actions/       # Action definitions (move, harvest, attack, construct)
  buildings/     # HQ, Barracks, Vehicle Factory, Bandwidth Relay
  units/         # Worker, Rifle Infantry, Scout, Engineer
components/      # Reusable component scripts attached to actor nodes
system/          # Singleton-style game systems
world/
  missions/      # Mission scenes, controllers, HUD, and UI panels
  resources/     # Harvestable resource nodes
ui/              # Hub menu and meta UI
z_assets/        # 3D models, textures, shaders (prefixed z_ to sort last)
```

### Key Systems

**Economy (`system/mission_economy.gd`)** — The central manager for the mission layer. Tracks Crystals/Bits/Protocol Fragments, unit and building costs, supply cap, and is responsible for instantiating and registering all units/buildings. Nearly everything that spawns goes through this file.

**Unit Action Queue (`components/unit_actions_component.gd`)** — Queue-based command system on units. Registered action types: Move, Harvest, Attack, Construct. Handles action priority and transitions.

**Production (`components/production_component.gd`)** — Attached to buildings; manages build queues, timers, and exposes action offers to the HUD.

**Selection & Orders (`world/missions/selection_controller.gd`, `order_controller.gd`)** — Handle mouse selection of units/buildings and translate player clicks into orders dispatched to the action queue.

**Placement (`world/missions/placement_controller.gd`)** — Grid-based validation for placing structures; checks footprint collisions against existing buildings.

**Health (`components/health_component.gd`)** — Attached to any actor that can take damage; emits signals for death and repair events.

**HUD (`world/missions/hud.gd`)** — Displays resources, selected unit/building status, and action buttons. Listens to economy and selection signals.

### Units & Buildings (Prototype Scope)

| Actor | Role |
|---|---|
| Worker | Harvests Crystals/Bits, constructs buildings |
| Rifle Infantry | Basic ranged attack unit |
| Scout | Fast vehicle, medium attack |
| Engineer | Starts mission, transforms into first HQ |
| HQ | Produces Workers, resource drop-off |
| Barracks | Produces Rifle Infantry |
| Vehicle Factory | Produces Scouts |
| Bandwidth Relay | Increases supply cap |

## GDScript Coding Standards

**Explicit typing is enforced** — never use `:=` for type inference; always annotate variables and return types explicitly. See `.cursor/rules/gdscript-explicit-typing.mdc` for full rules.

**Scene UIDs** — use path-based `preload`/`load` references; do not manually edit or copy UIDs between files. Let Godot manage UID assignments. See `.cursor/rules/godot-scene-uid-policy.mdc`.

## Design Documents

- `ProtoGDD.md` — Prototype scope: the vertical slice (mission 1, static units, win/loss conditions)
- `FullGDD.md` — Full game vision: modular unit/building designer, campaign, meta progression
- `architecture_guide.md` — Component-first philosophy with implementation examples
