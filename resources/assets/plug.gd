extends CharacterBody2D

@export var offset := 0.0
@onready var cable: Node2D = $".."
@onready var area: Area2D = $Area2D

@export var dragging_speed = 50

var dragging := false
var connected_socket = null
var normal_scale
var hover_scale
var scale_tween: Tween = null

signal connected(socket)

func _ready() -> void:
	normal_scale = scale
	hover_scale = scale * 1.1

	area.input_event.connect(_on_area_input_event)
	area.mouse_entered.connect(_on_area_mouse_entered)
	area.mouse_exited.connect(_on_area_mouse_exited)

func _on_area_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		dragging = true

		if connected_socket:
			cable.remove_socket(connected_socket)
			connected_socket.occupied = false
			connected_socket = null

func _input(event):
	if not dragging:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		dragging = false
		await get_tree().physics_frame
		tween_to_scale(normal_scale)
		try_connect()

func _physics_process(_delta):
	if dragging:
		var target = get_global_mouse_position()
		var direction = target - global_position
		
		velocity = direction * dragging_speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

func try_connect():
	var areas = $Area2D.get_overlapping_areas()

	for area in areas:
		if area.is_in_group("socket") and not area.occupied:
			global_position = Vector2(area.global_position.x + offset, area.global_position.y)
			connected_socket = area
			area.occupied = true
			cable.add_socket(area)
			cable.update_cable()
			print(name + " connected to " + area.pair_id)
			return

func tween_to_scale(target_scale: Vector2) -> void:
	if scale_tween != null:
		scale_tween.kill()

	scale_tween = create_tween()
	scale_tween.set_trans(Tween.TRANS_SINE)
	scale_tween.set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(self, "scale", target_scale, 0.1)

func _on_area_mouse_entered() -> void:
	tween_to_scale(hover_scale)

func _on_area_mouse_exited() -> void:
	if not dragging:
		tween_to_scale(normal_scale)
