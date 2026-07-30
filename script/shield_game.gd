extends CanvasLayer

## Schild-Reparatur — Frequenz-Kalibrierung.
##
## Das gesamte Layout liegt als Control-Knoten (Container) in ShieldGame.tscn:
##   Center(CenterContainer) > Panel(PanelContainer) > Margin > VBox
##     > Title / Sub / Channels(VBox) / Status / Buttons(HBox)
##   jeder Kanal = HBoxContainer { Info(VBox: Name,Value) | Scope(Panel: Sine) | Slot(Knob) }
## Alles ist im Editor frei verschieb-/skalierbar. Dieses Skript macht nur Logik.
##
## SOLLWERTE stehen NUR im Handbuch (Tab „Schild"), dort verzerrt. „Schild
## stabilisieren" prueft, ob alle Knoepfe nahe genug am Sollwert sind.
##
## Kanaele werden dynamisch erkannt: jedes Kind von Channels mit Slot/Knob,
## Scope/Sine und Info/Value zaehlt. Kanal hinzufuegen = Channel-Knoten
## duplizieren + Wert in `targets` ergaenzen.

## Sollwerte pro Kanal (Reihenfolge wie die Channel-Knoten). MUSS zum Handbuch passen!
@export var targets: Array[int] = [43, 68, 25]
## Erlaubte Abweichung pro Kanal (0 = exakt).
@export_range(0, 5, 1) var tolerance: int = 1

var malfunction = null

const COL_GREEN := Color(0.30, 1.0, 0.55)
const COL_RED := Color(1.0, 0.45, 0.45)

@onready var _channels_root: VBoxContainer = $Center/Panel/Margin/VBox/Channels
@onready var _status: Label = $Center/Panel/Margin/VBox/Status
@onready var _confirm_bt: Button = $Center/Panel/Margin/VBox/Buttons/ConfirmBt
@onready var _back_bt: Button = $Center/Panel/Margin/VBox/Buttons/BackBt
@onready var error_code: Node2D = $ErrorCode

var _knobs: Array = []
var _slots: Array = []
var _scopes: Array = []
var _lines: Array = []
var _vals: Array = []
var _solved := false
var _phase := 0.0

func _ready() -> void:
	_collect_channels()
	_apply_styles()
	for i in _knobs.size():
		_knobs[i].value_changed.connect(_on_knob_changed.bind(i))
		_vals[i].text = str(_knobs[i].value)
	_confirm_bt.pressed.connect(_on_confirm)
	_back_bt.pressed.connect(_on_back)

## Findet pro Kanal-Zeile die Teilknoten (Slot/Knob, Scope/Sine, Info/Value).
func _collect_channels() -> void:
	for ch in _channels_root.get_children():
		if not (ch.has_node("Slot/Knob") and ch.has_node("Scope/Sine") and ch.has_node("Info/Value")):
			continue
		_knobs.append(ch.get_node("Slot/Knob"))
		_slots.append(ch.get_node("Slot"))
		_scopes.append(ch.get_node("Scope"))
		_lines.append(ch.get_node("Scope/Sine"))
		_vals.append(ch.get_node("Info/Value"))

## Dunkle Konsolen-Optik nur setzen, falls in der Szene kein eigener Stil gesetzt wurde.
func _apply_styles() -> void:
	var panel := $Center/Panel
	if not panel.has_theme_stylebox_override("panel"):
		panel.add_theme_stylebox_override("panel", _style(Color(0.055, 0.078, 0.11), Color(0.17, 0.44, 0.54), 16, 3))
	for scope in _scopes:
		if not scope.has_theme_stylebox_override("panel"):
			scope.add_theme_stylebox_override("panel", _style(Color(0.03, 0.09, 0.07), Color(0.2, 0.5, 0.4), 8, 2))

func _style(bg: Color, border: Color, radius: int, bw: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(bw)
	sb.border_color = border
	return sb

func _on_knob_changed(value: int, i: int) -> void:
	_vals[i].text = str(value)

func _process(delta: float) -> void:
	_phase += delta * 2.2
	for i in _knobs.size():
		# Knopf in seinem (vom Container vergebenen) Slot zentrieren.
		_knobs[i].position = _slots[i].size * 0.5
		_redraw_sine(i)

func _redraw_sine(i: int) -> void:
	var k = _knobs[i]
	var scope: Control = _scopes[i]
	var sz := scope.size
	var line: Line2D = _lines[i]
	line.position = sz * 0.5                       # Mitte der Box (lokal zur Scope)
	var w := maxf(sz.x - 16.0, 40.0)
	var amp := sz.y * 0.36
	var cycles: float = remap(float(k.value), float(k.value_min), float(k.value_max), 1.0, 8.0)
	var n := 72
	var pts := PackedVector2Array()
	for s in n + 1:
		var fx := float(s) / float(n)
		var x := (fx - 0.5) * w
		var y := -amp * sin(fx * cycles * TAU + _phase)
		pts.append(Vector2(x, y))
	line.points = pts

func _on_confirm() -> void:
	if _solved:
		return
	var off := 0
	for i in _knobs.size():
		var tgt: int = targets[i] if i < targets.size() else 0
		if absi(_knobs[i].value - tgt) > tolerance:
			off += 1
	if off == 0:
		_win()
	else:
		var word := "Kanal" if off == 1 else "Kanaele"
		_status.add_theme_color_override("font_color", COL_RED)
		_status.text = "Frequenzen nicht synchron"

func _win() -> void:
	if _solved:
		return
	_solved = true
	_confirm_bt.disabled = true
	for line in _lines:
		line.width = 5.0
		line.default_color = COL_GREEN
	for k in _knobs:
		k.set_process(false)
	_status.add_theme_color_override("font_color", COL_GREEN)
	_status.text = "SCHILD STABIL"
	error_code.lamp_flash()
	AudioManager.play_success()
	await get_tree().create_timer(0.75).timeout
	if malfunction:
		malfunction.mark_solved()
	SceneSwitcher.close_overlay_scene()

func _on_back() -> void:
	SceneSwitcher.close_overlay_scene()
