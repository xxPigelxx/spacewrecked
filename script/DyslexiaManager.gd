# DyslexiaManager.gd
# Autoload singleton — Project > Project Settings > Autoload
# Name: DyslexiaManager
#
# Reads a PageConfig resource and processes raw text into
# BBCode-formatted output for a RichTextLabel.
# No stress system — effects are fully defined per page.

extends Node

# ─────────────────────────────────────────────
#  SIGNALS
# ─────────────────────────────────────────────

## Emitted when a new page config is loaded.
signal page_loaded(config: PageConfig)

# ─────────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────────

## The currently active page config.
var current_config: PageConfig = null

## Master accessibility override — set true to disable ALL effects.
var accessibility_mode: bool = false

var _rng := RandomNumberGenerator.new()

const SWAP_PAIRS: Dictionary = {
	"b": "d", "d": "b",
	"p": "q", "q": "p",
	"n": "u", "u": "n",
	"m": "w", "w": "m",
	"6": "9", "9": "6",
	"2": "5", "5": "2",
}

# ─────────────────────────────────────────────
#  LOAD A PAGE
# ─────────────────────────────────────────────

## Call this when opening a manual page.
##
## Example:
##   var config = load("res://resources/pages/page_oxygen_valve.tres")
##   DyslexiaManager.load_page(config)
##   DyslexiaManager.apply_font_to_label($ManualLabel)
##   $ManualLabel.text = DyslexiaManager.process_text()
func load_page(config: PageConfig) -> void:
	current_config = config
	_rng.seed = config.seed
	page_loaded.emit(config)


# ─────────────────────────────────────────────
#  PROCESS TEXT
# ─────────────────────────────────────────────

## Returns processed BBCode for the current page's raw_text.
func process_text() -> String:
	if current_config == null:
		push_warning("DyslexiaManager: no page loaded — call load_page() first.")
		return ""
	if accessibility_mode:
		return current_config.raw_text

	_rng.seed = current_config.seed

	var words := current_config.raw_text.split(" ", false)
	var result: PackedStringArray = []

	for i in words.size():
		var word := words[i]
		word = _apply_word_mirror(word)
		word = _apply_letter_swap(word)
		word = _apply_drift(word, i)
		word = _apply_size_variation(word)
		result.append(word)

	var joined := _apply_river_spacing(result)

	if current_config.enable_line_overlap:
		joined = _apply_line_overlap(joined)

	return joined


## Process arbitrary text with the current page's effects.
## Use for warning boxes, step text etc.
func process_custom_text(raw: String) -> String:
	if current_config == null or accessibility_mode:
		return raw
	_rng.seed = current_config.seed + 500
	var words := raw.split(" ", false)
	var result: PackedStringArray = []
	for i in words.size():
		var word := words[i]
		word = _apply_letter_swap(word)
		word = _apply_drift(word, i)
		result.append(word)
	return _apply_river_spacing(result)


# ─────────────────────────────────────────────
#  FONT HELPER
# ─────────────────────────────────────────────

## Apply this page's font settings to a RichTextLabel.
func apply_font_to_label(label: RichTextLabel) -> void:
	if current_config == null:
		return
	if current_config.font != null:
		label.add_theme_font_override("normal_font", current_config.font)
	label.add_theme_font_size_override("normal_font_size", current_config.font_size)
	if current_config.enable_line_overlap:
		label.add_theme_constant_override("line_separation", -6)
	else:
		label.remove_theme_constant_override("line_separation")


# ─────────────────────────────────────────────
#  INTERNAL EFFECTS
# ─────────────────────────────────────────────

func _apply_letter_swap(word: String) -> String:
	if not current_config.enable_letter_swap:
		return word
	var out := ""
	for i in word.length():
		var ch := word[i]
		var lower := ch.to_lower()
		if lower in SWAP_PAIRS and _rng.randf() < current_config.swap_chance:
			var swapped: String = SWAP_PAIRS[lower]
			if ch == ch.to_upper() and ch != ch.to_lower():
				swapped = swapped.to_upper()
			out += "[color=#8b2000]%s[/color]" % swapped
		else:
			out += ch
	return out


func _apply_drift(word: String, word_index: int) -> String:
	if not current_config.enable_word_drift:
		return word
	var amp := current_config.drift_amplitude
	var freq := current_config.drift_frequency
	var phase := fmod(word_index * 0.41, 1.0)
	return "[wave amp=%.1f freq=%.2f]%s[/wave]" % [amp, freq + phase, word]


func _apply_size_variation(word: String) -> String:
	if not current_config.enable_size_variation:
		return word
	var base := current_config.font_size
	var range_val := current_config.size_variation_range
	var size := base + int(_rng.randf_range(-range_val, range_val))
	size = clampi(size, 8, 64)
	return "[font_size=%d]%s[/font_size]" % [size, word]


func _apply_river_spacing(words: PackedStringArray) -> String:
	if not current_config.enable_river_spacing:
		return " ".join(words)
	var parts: PackedStringArray = []
	for i in words.size():
		parts.append(words[i])
		if i < words.size() - 1:
			var extra := int(_rng.randf() * current_config.river_max_gap)
			if extra > 0:
				parts.append(" ".repeat(extra))
	return "".join(parts)


func _apply_word_mirror(word: String) -> String:
	if not current_config.enable_word_mirror:
		return word
	if _rng.randf() < current_config.mirror_chance:
		return word.reverse()
	return word


func _apply_line_overlap(text: String) -> String:
	var lines := text.split("\n")
	var result: PackedStringArray = []
	for line in lines:
		result.append(line)
		if _rng.randf() < 0.3:
			result.append("[font_size=4] [/font_size]")
	return "\n".join(result)
