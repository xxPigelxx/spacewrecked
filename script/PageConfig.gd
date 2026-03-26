# PageConfig.gd
# A Resource you fill in per manual page — in the Godot Inspector.
# Create one .tres file per puzzle/page:
#   Right-click in FileSystem > New Resource > PageConfig
#
# EXAMPLE SETUP IN INSPECTOR:
#   page_id:        "oxygen_valve"
#   section_label:  "Section 3.1"
#   page_number:    4
#   raw_text:       "Locate the red valve marked OXYGEN-A..."
#   font:           (drag in OpenDyslexic.ttf)
#   font_size:      16
#   enable_letter_swap:   true
#   enable_word_drift:    false
#   enable_river_spacing: true
#   enable_line_overlap:  false
#   enable_size_variation: false
#   seed:           1001   ← same seed = same errors every read

@tool  # allows preview in editor
extends Resource

class_name PageConfig

# ─────────────────────────────────────────────
#  IDENTITY
# ─────────────────────────────────────────────

## Unique ID — used to track which pages the player has read.
@export var page_id: String = ""

## Shown in the top-left header of the manual page.
@export var section_label: String = "Section 3.1"

## Shown in the top-right of the manual page.
@export var page_number: int = 1

## The title shown at the top of the page.
@export var page_title: String = ""

# ─────────────────────────────────────────────
#  CONTENT
# ─────────────────────────────────────────────

## The raw body text of the manual page (unprocessed).
@export_multiline var raw_text: String = ""

## Warning box text shown below the body (leave empty to hide).
@export_multiline var warning_text: String = ""

## Step-by-step instructions shown below the warning.
@export var steps: Array[String] = []

# ─────────────────────────────────────────────
#  FONT
# ─────────────────────────────────────────────

## The font to use for this page's body text.
## Drag in OpenDyslexic, a bitmap font, or leave null for default.
@export var font: FontFile = null

## Base font size for body text.
@export_range(10, 32) var font_size: int = 15

## If true, randomly varies font size per word (river-like density effect).
@export var enable_size_variation: bool = false

## Range of size variation when enable_size_variation is true.
@export_range(0, 8) var size_variation_range: int = 4

# ─────────────────────────────────────────────
#  DYSLEXIA EFFECTS
# ─────────────────────────────────────────────

## Swap visually similar letters: b↔d, p↔q, n↔u, 6↔9
@export var enable_letter_swap: bool = false

## Probability of each eligible letter being swapped (0.0 – 1.0).
@export_range(0.0, 1.0, 0.05) var swap_chance: float = 0.25

## Letters float/bob vertically using [wave] BBCode.
@export var enable_word_drift: bool = false

## How high letters drift (pixels).
@export_range(0.0, 20.0, 0.5) var drift_amplitude: float = 4.0

## How fast the drift oscillates.
@export_range(0.1, 5.0, 0.1) var drift_frequency: float = 1.2

## Randomise spacing between words to create visual rivers.
@export var enable_river_spacing: bool = false

## Maximum extra spaces injected between words.
@export_range(0, 20) var river_max_gap: int = 10

## Lines crowd each other using compressed line height.
@export var enable_line_overlap: bool = false

## Randomly mirror whole words (severe — use sparingly).
@export var enable_word_mirror: bool = false

## Probability a word gets mirrored when enable_word_mirror is true.
@export_range(0.0, 1.0, 0.05) var mirror_chance: float = 0.15

# ─────────────────────────────────────────────
#  RANDOMISATION
# ─────────────────────────────────────────────

## Seed for the RNG. Same seed = same error pattern every time
## the player opens this page. Set different seeds per page.
@export var seed: int = 1001
