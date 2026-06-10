---
name: puzzle-malfunction-architecture
description: How malfunctions and puzzle overlays plug together in Spacewrecked
metadata:
  type: project
---

Spacewrecked is a Bachelor-thesis game: repair a wrecked ship against a countdown while a dyslexia-simulation distorts on-screen text (ship health → `DyslexiaManager.stress` → text distortion; runs logged to `user://results.csv`).

**Malfunction → puzzle contract (follow this for any new task/puzzle):**
- A `MalfunctionInteractable` (`script/malfunction_interactable.gd`, extends `Interactable`/`Area2D`) is placed as a node in `Scenes/MainGame.tscn` under `Interactabels/MalfunctionSpawner`. Key exports: `category` (enum: NICHT_GESETZT=0, STROM=1, TREIBSTOFF=2, SCHILD=3, NAVIGATION=4), `phase` (TUTORIAL=0, JOURNEY=1), `spawn_time` (sec into journey), `overlay_scene` (path to puzzle .tscn). Needs child nodes: `CollisionShape2D`, `Sprite2D`, `RichTextLabel` (must be named exactly that — `interactable.gd` does `get_node_or_null("RichTextLabel")`).
- On interact, it calls `SceneSwitcher.open_overlay_with_data(overlay_scene, {"malfunction": self})`. `open_overlay_with_data` sets each dict key as a property on the puzzle's root node.
- The puzzle root needs `var malfunction = null`. On solve it calls `malfunction.mark_solved()` then `SceneSwitcher.close_overlay_scene()`. `mark_solved()` clears the `broken_<category>` counter, restores health, adds score (JOURNEY only).
- The autoload is `GameState` (= `script/GameManager.gd`); also `DyslexiaManager`, `SceneSwitcher`.

**Shield puzzle (added):** `Scenes/Puzzle/ShieldGame.tscn` + `script/shield_game.gd` — frequency-calibration: 3 rotary knobs (`script/calibration_knob.gd`, `class_name CalibrationKnob`, reuses the cockpit Ring+Knob sprite regions from Procreate_Sprites.png) set 3 sine curves; target values (43/68/25) are NOT shown in the puzzle — they live (dyslexia-distorted) on the manual's "Schild" tab in `Scenes/Manual_NEU.tscn`. So `shield_game.gd` `channels[].target` MUST stay in sync with the Schild page StepList (S3/S4/S5). Wired as a SCHILD malfunction (`ShieldMalfunction`, spawn_time 6) in MainGame. UI is built in code.

Manual pages live as TabContainer children in `Scenes/Manual_NEU.tscn` (Home/Energie/Treibstoff/Navigation/Schild/Codes). Each page Control has `PageEffects` (per-page dyslexia knobs: swap/mirror/river/…) applied to all `DyslexiaLabel` (RichTextLabel) descendants. Puzzle answers are authored into these pages (e.g. nav order, door codes, shield frequencies) and kept in sync with the puzzle's exported values by hand.

Note: `MalfunctionInteractable._action()` passes only `{"malfunction": self}` — it ignores the base `overlay_data` export, so puzzles use their own scene `@export` defaults for config. Adding nodes via the godot MCP `add_node` applies properties *before* attaching the script, so script-defined exports must be set with a follow-up `set_node_properties`. See [[godot-mcp-scene-editing]].
