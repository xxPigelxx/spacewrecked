class_name CalibrationKnob
extends Node2D

## Dreh-Regler, der seinen Wert HÄLT (anders als der Joystick im Cockpit).
## Die Knoten (Ring / Dial / Knob / Tick / Hit) liegen in CalibrationKnob.tscn
## und sind dort frei editierbar. Ziehen nach rechts/im Uhrzeigersinn erhoeht
## den Wert. Sendet value_changed(value) bei jeder Aenderung.

signal value_changed(value: int)

@export var value_min: int = 10
@export var value_max: int = 90
@export var start_value: int = 10
## Halber Drehbereich in Grad (ab "oben"). 140 => 280° Gesamtweg.
@export var sweep_deg: float = 140.0

@onready var _dial: Node2D = $Dial
@onready var _tick: Line2D = $Dial/Tick
@onready var _hit: Button = $Hit

var value: int = 10
var _dragging := false

func _ready() -> void:
	value = clampi(start_value, value_min, value_max)
	# Zeiger nur setzen, falls in der Szene keiner gezeichnet wurde.
	if _tick and _tick.points.is_empty():
		_tick.points = PackedVector2Array([Vector2(0, -10), Vector2(0, -46)])
	if _hit and not _hit.button_down.is_connected(_on_grab):
		_hit.button_down.connect(_on_grab)
	_update_dial()

func _on_grab() -> void:
	_dragging = true

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
