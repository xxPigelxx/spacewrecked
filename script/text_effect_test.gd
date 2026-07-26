# text_effect_test.gd — Testszene: zeigt ALLE Text-Effekte gleichzeitig untereinander.
#
# Jede Zeile ist ein eigenes DyslexiaLabel mit override_page = true und genau EINEM
# aktiven Effekt, alle mit demselben Satz und demselben Seed. So laesst sich jeder
# Effekt isoliert beurteilen und direkt mit der Referenzzeile oben vergleichen.
#
# Der Aufbau passiert komplett im Code: die Effektliste unten ist die einzige
# Stelle, die man anfassen muss, wenn ein Effekt dazukommt oder Werte nicht passen.
extends Control

## Enthaelt bewusst b/d, p/q, n/u, m/w — sonst sieht man beim Swap-Effekt nichts.
const SAMPLE := "Die Bordkanone braucht Wartung und muss neu kalibriert werden."

## [Anzeigename, { DyslexiaLabel-Property: Wert }]
const ROWS: Array = [
	["Referenz (aus)",   {}],
	["Vanish (pulsend)", {"vanish_percent": 50.0}],
	["Swap (b/d, p/q)",  {"swap_percent": 70.0}],
	["Mirror",           {"mirror_percent": 50.0}],
	["Scramble",         {"scramble_percent": 70.0}],
	["Transposition",    {"transpose_percent": 60.0}],
	["Crowding",         {"crowd_percent": 100.0}],
	["Groessen-Varianz", {"size_variation": 6.0}],
	["River Spacing",    {"river_spacing": 10.0}],
	["Drift / Welle",    {"drift_amplitude": 6.0, "drift_frequency": 1.5}],
	["Shake",            {"shake_amplitude": 6.0}],
	["Tornado",          {"tornado_radius": 6.0, "tornado_frequency": 1.5}],
	["Pulse",            {"pulse_frequency": 2.0}],
	["Rotation",         {"rotate_percent": 60.0}],
	["Zeichen-Groesse",  {"char_size_percent": 100.0}],
	["Fehlende Teile",   {"missing_percent": 30.0}],
	["Font-Wechsel",     {"font_percent": 60.0}],
	["Phonetisch (Laut)",{"phonetic_percent": 100.0}],
	["ALLES kombiniert", {
		"vanish_percent": 10.0, "swap_percent": 25.0, "mirror_percent": 15.0,
		"scramble_percent": 25.0, "transpose_percent": 15.0, "crowd_percent": 50.0,
		"size_variation": 3.0, "river_spacing": 4.0,
		"drift_amplitude": 3.0, "drift_frequency": 1.2,
		"shake_amplitude": 2.0, "pulse_frequency": 1.0,
		"rotate_percent": 25.0, "missing_percent": 15.0, "char_size_percent": 40.0,
		"font_percent": 40.0,
	}],
]

const LABEL_WIDTH := 620
const NAME_WIDTH := 190

var _labels: Array[DyslexiaLabel] = []
var _seed: int = 1000
var _stress_value: Label


func _ready() -> void:
	theme = load("res://resources/themes/main_theme.tres")
	_build()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#d9d3c6")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)

	column.add_child(_build_controls())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 16)
	scroll.add_child(grid)

	for row in ROWS:
		var effect_name: String = row[0]
		var props: Dictionary = row[1]
		grid.add_child(_build_name_cell(effect_name, props))
		var lbl := _build_effect_label(props)
		grid.add_child(lbl)
		_labels.append(lbl)


func _build_controls() -> Control:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 16)

	var stress_name := Label.new()
	stress_name.text = "Stress"
	box.add_child(stress_name)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.value = DyslexiaManager.stress
	slider.custom_minimum_size = Vector2(240, 0)
	slider.value_changed.connect(_on_stress_changed)
	box.add_child(slider)

	_stress_value = Label.new()
	_stress_value.custom_minimum_size = Vector2(48, 0)
	_stress_value.text = "%d" % int(DyslexiaManager.stress)
	box.add_child(_stress_value)

	var access := CheckBox.new()
	access.text = "Barrierefrei (alles aus)"
	access.button_pressed = DyslexiaManager.accessibility
	access.toggled.connect(_on_accessibility_toggled)
	box.add_child(access)

	var spacing := CheckBox.new()
	spacing.text = "Rotation: Platz reservieren"
	spacing.button_pressed = DyslexiaManager.rotate_spacing
	spacing.toggled.connect(_on_rotate_spacing_toggled)
	box.add_child(spacing)

	var reroll := Button.new()
	reroll.text = "Neu wuerfeln"
	reroll.pressed.connect(_on_reroll_pressed)
	box.add_child(reroll)

	return box


func _build_name_cell(effect_name: String, props: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(NAME_WIDTH, 0)
	box.add_theme_constant_override("separation", 0)

	var title := Label.new()
	title.text = effect_name
	box.add_child(title)

	var params := Label.new()
	params.add_theme_font_size_override("font_size", 12)
	params.add_theme_color_override("font_color", Color("#00000099"))
	params.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	params.custom_minimum_size = Vector2(NAME_WIDTH, 0)
	var parts: PackedStringArray = []
	for key in props:
		parts.append("%s=%s" % [key, props[key]])
	params.text = "—" if parts.is_empty() else ", ".join(parts)
	box.add_child(params)

	return box


func _build_effect_label(props: Dictionary) -> DyslexiaLabel:
	var lbl := DyslexiaLabel.new()
	# Properties VOR add_child setzen: _ready() liest text/rng_seed einmalig ein
	# und rendert direkt — spaeter gesetzte Werte brauchten sonst ein refresh().
	lbl.override_page = true
	lbl.text = SAMPLE
	lbl.rng_seed = _seed
	for key in props:
		lbl.set(key, props[key])
	lbl.custom_minimum_size = Vector2(LABEL_WIDTH, 0)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return lbl


func _on_stress_changed(value: float) -> void:
	DyslexiaManager.stress = value
	_stress_value.text = "%d" % int(value)


func _on_rotate_spacing_toggled(pressed: bool) -> void:
	DyslexiaManager.rotate_spacing = pressed


func _on_accessibility_toggled(pressed: bool) -> void:
	DyslexiaManager.accessibility = pressed


func _on_reroll_pressed() -> void:
	_seed += 1
	for lbl in _labels:
		lbl.rng_seed = _seed
		lbl.refresh()
