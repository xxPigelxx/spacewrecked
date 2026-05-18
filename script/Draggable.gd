class_name Draggable
extends CharacterBody2D

@export var dragging_speed: float = 50.0
@export var hover_scale_multiplier: float = 1.1

@onready var area: Area2D = $Area2D

var dragging := false
var normal_scale: Vector2
var hover_scale: Vector2
var scale_tween: Tween = null

signal drag_started
signal drag_ended

func _ready() -> void:
	normal_scale = scale
	hover_scale = scale * hover_scale_multiplier

	area.input_event.connect(_on_area_input_event)
	area.mouse_entered.connect(_on_area_mouse_entered)
	area.mouse_exited.connect(_on_area_mouse_exited)
	_set_up()


func _on_area_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			_on_drag_started()
			drag_started.emit()

func _input(event: InputEvent) -> void:
	if not dragging:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		dragging = false
		await get_tree().physics_frame
		tween_to_scale(normal_scale)
		_on_drag_ended()
		drag_ended.emit()

func _physics_process(delta: float) -> void:
	if dragging:
		var target := get_global_mouse_position()
		var desired_velocity := (target - global_position) * dragging_speed

		velocity = desired_velocity
		move_and_slide()

		for i in get_slide_collision_count():
			var collision := get_slide_collision(i)
			var normal := collision.get_normal()

			if desired_velocity.dot(normal) < 0.0:
				velocity = velocity.slide(normal)

		_while_dragging(delta)
	else:
		velocity = Vector2.ZERO
		move_and_slide()

func tween_to_scale(target_scale: Vector2) -> void:
	if scale_tween:
		scale_tween.kill()

	scale_tween = create_tween()
	scale_tween.set_trans(Tween.TRANS_SINE)
	scale_tween.set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(self, "scale", target_scale, 0.1)

func _on_area_mouse_entered() -> void:
	tween_to_scale(hover_scale)
	_on_mouse_enterd()

func _on_area_mouse_exited() -> void:
	if not dragging:
		tween_to_scale(normal_scale)
	_on_mouse_exited()

func _on_drag_started() -> void:
	pass

func _on_drag_ended() -> void:
	pass

func _while_dragging(_delta: float) -> void:
	pass

func _set_up():
	pass
func _on_mouse_enterd():
	pass
func _on_mouse_exited():
	pass
