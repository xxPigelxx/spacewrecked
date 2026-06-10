extends CanvasLayer

## Schild-Reparatur — Frequenz-Kalibrierung (Knopf-Version).
##
## Drei Dreh-Regler (CalibrationKnob) stellen je eine Frequenz ein; eine
## Sinuskurve dient als Live-Feedback. Die SOLLWERTE stehen NUR im Handbuch
## (Tab „Schild") und werden dort vom Dyslexie-Effekt verzerrt (z. B. 43->34,
## 6<->9, 2<->5). Erst wenn alle Regler nahe genug am Sollwert sind und
## „Schild stabilisieren" gedrueckt wird, gilt das Schild als repariert.
##
## Plug-in-Vertrag (wie alle Puzzles):
##   - wird als Overlay geoeffnet; "malfunction" wird per Property gesetzt
##   - bei Loesung: malfunction.mark_solved() + SceneSwitcher.close_overlay_scene()

@export var category: String = "schild"

## Kanaele: { "name": String, "target": int }.
## WICHTIG: target muss zu den Werten auf der Handbuch-Seite „Schild" passen!
@export var channels: Array[Dictionary] = [
	{"name": "Kanal A", "target": 43},
	{"name": "Kanal B", "target": 68},
	{"name": "Kanal C", "target": 25},
]
@export var value_min: int = 10
@export var value_max: int = 90
## Erlaubte Abweichung pro Kanal (0 = exakt).
@export_range(0, 5, 1) var tolerance: int = 1

# --- vom SceneSwitcher gesetzt ---
var malfunction = null

# --- Laufzeit ---
var _knobs: Array[CalibrationKnob] = []
var _lines: Array[Line2D] = []
var _readouts: Array[Label] = []
var _values: Array[int] = []
var _status: Label
var _confirm_bt: Button
var _solved := false
var _phase := 0.0

const PANEL_W := 900.0
const PANEL_H := 640.0
const SINE_W := 360.0
const SINE_H := 110.0
const COL_GREEN := Color(0.30, 1.0, 0.55)
const COL_CYAN := Color(0.45, 0.85, 1.0)
const COL_RED := Color(1.0, 0.45, 0.45)

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var px := (1920.0 - PANEL_W) * 0.5
	var py := (1080.0 - PANEL_H) * 0.5

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := Panel.new()
	panel.position = Vector2(px, py)
	panel.size = Vector2(PANEL_W, PANEL_H)
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var title := _label("SCHILD-FREQUENZEN KALIBRIEREN", 30, COL_CYAN)
	title.position = Vector2(px, py + 22)
	title.size = Vector2(PANEL_W, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	var sub := _label("Sollwerte stehen im Handbuch  ▸  Tab „Schild“.", 18, Color(0.7, 0.78, 0.85))
	sub.position = Vector2(px, py + 64)
	sub.size = Vector2(PANEL_W, 26)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)

	var first_y := py + 150.0
	var row_gap := 150.0
	for i in channels.size():
		_build_channel(i, px, first_y + i * row_gap)

	_status = _label("", 20, COL_CYAN)
	_status.position = Vector2(px, py + PANEL_H - 132)
	_status.size = Vector2(PANEL_W, 28)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_status)

	_confirm_bt = Button.new()
	_confirm_bt.text = "Schild stabilisieren"
	_confirm_bt.position = Vector2(px + PANEL_W * 0.5 - 270, py + PANEL_H - 88)
	_confirm_bt.size = Vector2(270, 58)
	_confirm_bt.pressed.connect(_on_confirm)
	add_child(_confirm_bt)

	var back := Button.new()
	back.text = "Zurueck"
	back.position = Vector2(px + PANEL_W * 0.5 + 30, py + PANEL_H - 88)
	back.size = Vector2(180, 58)
	back.pressed.connect(_on_back)
	add_child(back)

func _build_channel(i: int, px: float, cy: float) -> void:
	var box_x := px + 130.0

	var frame := Panel.new()
	frame.position = Vector2(box_x, cy - SINE_H * 0.5)
	frame.size = Vector2(SINE_W, SINE_H)
	frame.add_theme_stylebox_override("panel", _scope_style())
	add_child(frame)

	var line := Line2D.new()
	line.width = 3.0
	line.default_color = COL_GREEN
	line.position = Vector2(box_x + SINE_W * 0.5, cy)   # Mitte der Box
	add_child(line)
	_lines.append(line)

	var knob := CalibrationKnob.new()
	knob.value_min = value_min
	knob.value_max = value_max
	knob.scale = Vector2(0.7, 0.7)
	knob.position = Vector2(px + PANEL_W - 120, cy)
	knob.set_value(value_min)
	knob.value_changed.connect(_on_knob_changed.bind(i))
	add_child(knob)
	_knobs.append(knob)

	var name_lbl := _label(str(channels[i].get("name", "Kanal")), 22, COL_CYAN)
	name_lbl.position = Vector2(px + 26, cy - 32)
	name_lbl.size = Vector2(96, 28)
	add_child(name_lbl)

	var val_lbl := _label(str(value_min), 34, Color.WHITE)
	val_lbl.position = Vector2(px + 26, cy + 0)
	val_lbl.size = Vector2(96, 40)
	add_child(val_lbl)
	_readouts.append(val_lbl)

	_values.append(value_min)

func _on_knob_changed(value: int, i: int) -> void:
	_values[i] = value
	_readouts[i].text = str(value)

func _process(delta: float) -> void:
	_phase += delta * 2.2
	for i in _lines.size():
		_redraw_sine(i)

func _redraw_sine(i: int) -> void:
	var v: int = _values[i]
	var cycles: float = remap(float(v), float(value_min), float(value_max), 1.0, 8.0)
	var amp: float = SINE_H * 0.38
	var n := 72
	var pts := PackedVector2Array()
	for s in n + 1:
		var fx := float(s) / float(n)
		var x := (fx - 0.5) * SINE_W
		var y := -amp * sin(fx * cycles * TAU + _phase)
		pts.append(Vector2(x, y))
	_lines[i].points = pts

func _on_confirm() -> void:
	if _solved:
		return
	var off := 0
	for i in _values.size():
		if absi(_values[i] - int(channels[i].get("target", 0))) > tolerance:
			off += 1
	if off == 0:
		_win()
	else:
		var word := "Kanal" if off == 1 else "Kanaele"
		_status.add_theme_color_override("font_color", COL_RED)
		_status.text = "Frequenzen nicht synchron — %d %s falsch eingestellt." % [off, word]

func _win() -> void:
	if _solved:
		return
	_solved = true
	_confirm_bt.disabled = true
	for line in _lines:
		line.default_color = COL_GREEN
		line.width = 5.0
	for knob in _knobs:
		knob.set_process(false)
	_status.add_theme_color_override("font_color", COL_GREEN)
	_status.text = "SCHILD STABIL — Reparatur abgeschlossen!"
	await get_tree().create_timer(0.9).timeout
	if malfunction:
		malfunction.mark_solved()
	SceneSwitcher.close_overlay_scene()

func _on_back() -> void:
	SceneSwitcher.close_overlay_scene()

func _label(txt: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l

func _panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.055, 0.078, 0.11)
	sb.set_corner_radius_all(16)
	sb.set_border_width_all(3)
	sb.border_color = Color(0.17, 0.44, 0.54)
	return sb

func _scope_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.09, 0.07)
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.2, 0.5, 0.4)
	return sb
