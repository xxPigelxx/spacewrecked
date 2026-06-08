extends Node2D

var door_open := false
var is_animating := false

@onready var top: StaticBody2D = $Top
@onready var bottom: StaticBody2D = $Bottom
@onready var lamp: Sprite2D = $Bottom/lamp
@onready var lamp_2: Sprite2D = $Top/lamp2

@export var move_by: float = 80.0
@export var duration: float = 0.35
@export var door_id := "keypad1"
@export var code := "1234"

@onready var keypad = $Keypad

var top_closed_pos: Vector2
var bottom_closed_pos: Vector2
var top_open_pos: Vector2
var bottom_open_pos: Vector2

var unlocked:= false

func _ready() -> void:
	top_closed_pos = top.position
	bottom_closed_pos = bottom.position
	
	top_open_pos = top_closed_pos + Vector2(0, -move_by)
	bottom_open_pos = bottom_closed_pos + Vector2(0, move_by)
	
	# puzzle_id und code an den Keypad weitergeben
	keypad.door_id = door_id
	keypad.code = code
	
	lamp.set_active(unlocked)
	lamp_2.set_active(unlocked)
	
func _physics_process(delta: float) -> void:
	unlocked = GameState.is_door_locked(door_id)	
	keypad.visible = !unlocked
	keypad.monitoring = !unlocked
	lamp.set_active(unlocked)
	lamp_2.set_active(unlocked)
	
func tween_door(top_target: Vector2, bottom_target: Vector2) -> void:
	is_animating = true

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(top, "position", top_target, duration)
	tween.tween_property(bottom, "position", bottom_target, duration)

	await tween.finished
	is_animating = false

func open_door() -> void:
	if door_open or is_animating:
		return
	if !GameState.is_door_locked(door_id):
		return
	await tween_door(top_open_pos, bottom_open_pos)
	door_open = true

func close_door() -> void:
	if not door_open or is_animating:
		return

	await tween_door(top_closed_pos, bottom_closed_pos)
	door_open = false

func _on_door_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		open_door()

func _on_door_detector_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		close_door()
