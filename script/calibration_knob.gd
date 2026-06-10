class_name CalibrationKnob
extends Node2D

## Dreh-Regler, der seinen Wert HÄLT (anders als der Joystick im Cockpit, der
## beim Loslassen zur Mitte zurueckspringt). Optik = Ring + Knopf aus den
## Cockpit-Sprites. Ziehen nach rechts (im Uhrzeigersinn) erhoeht den Wert.
## Sendet value_changed(value) bei jeder Aenderung.

signal value_changed(value: int)

const TEX: Texture2D = preload("res://resources/assets/Procreate_Sprites.png")
const RING_REGION := Rect2(273, 286, 209, 199)
const KNOB_REGION := Rect2(849, 323, 81, 81)

@export var value_min: int = 10
@export var value_max: int = 90
## Halber Drehbereich in Grad (ab "oben"). 140 => 280° Gesamtweg.
@export var sweep_deg: float = 140.0

var value: int = 50
var _dragging := false
var _dial: Node2D

func _ready() -> void:
	var ring := Sprite2D.new()
	ring.texture = TEX
	ring.region_enabled = true
	ring.region_rect = RING_REGION
	ring.modulate = Color(0.62, 0.68, 0.74)
	add_child(ring)

	_dial = Node2D.new()
	add_child(_dial)

	var knob := Sprite2D.new()
	knob.texture = TEX
	knob.region_enabled = true
	knob.region_rect = KNOB_REGION
	_dial.add_child(knob)

	# Zeiger nach oben, damit die Drehung sichtbar ist.
	var tick := Line2D.new()
	tick.points = PackedVector2Array([Vector2(0, -10), Vector2(0, -46)])
	tick.width = 7.0
	tick.default_color = Color(1.0, 0.85, 0.25)
	tick.begin_cap_mode = Line2D.LINE_CAP_ROUND
	tick.end_cap_mode = Line2D.LINE_CAP_ROUND
	_dial.add_child(tick)

	# Unsichtbarer Klickbereich zum Greifen.
	var hit := Button.new()
	hit.flat = true
	hit.modulate = Color(1, 1, 1, 0)
	hit.size = Vector2(150, 150)
	hit.position = Vector2(-75, -75)
	hit.button_down.connect(func() -> void: _dragging = true)
	add_child(hit)

	_update_dial()

func set_value(v: int) -> void:
	value = clampi(v, value_min, value_max)
	_update_dial()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_dragging = false

func _process(_delta: float) -> void:
	if not _dragging:
		return
	var dir := get_global_mouse_position() - global_position
	if dir.length() < 4.0:
		return
	var deg := clampf(rad_to_deg(Vector2.UP.angle_to(dir)), -sweep_deg, sweep_deg)
	var t := (deg + sweep_deg) / (2.0 * sweep_deg)
	var new_val := int(round(lerpf(float(value_min), float(value_max), t)))
	if new_val != value:
		value = new_val
		value_changed.emit(value)
	_update_dial()

func _update_dial() -> void:
	if _dial == null:
		return
	var t := float(value - value_min) / float(maxi(1, value_max - value_min))
	_dial.rotation = deg_to_rad(lerpf(-sweep_deg, sweep_deg, t))
