extends Node2D

var door_open := false
var is_animating := false

@onready var top: StaticBody2D = $Top
@onready var bottom: StaticBody2D = $Bottom

@export var move_by: float = 80.0
@export var duration: float = 0.35

var top_closed_pos: Vector2
var bottom_closed_pos: Vector2
var top_open_pos: Vector2
var bottom_open_pos: Vector2

var locked:= false

func _ready() -> void:
	top_closed_pos = top.position
	bottom_closed_pos = bottom.position

	top_open_pos = top_closed_pos + Vector2(0, -move_by)
	bottom_open_pos = bottom_closed_pos + Vector2(0, move_by)

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
	if door_open or is_animating or locked:
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
