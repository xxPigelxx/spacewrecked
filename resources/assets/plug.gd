extends Area2D

@export var offset := 0.0

var dragging := false
var connected_socket = null
var cable = null

var normal_scale := Vector2(0.35, 0.35)
var hover_scale := Vector2(0.4, 0.4)
var scale_tween: Tween = null

signal connected(socket)

func _ready() -> void:
	input_pickable = true
	monitoring = true
	monitorable = true
	scale = normal_scale
	set_process_input(false)

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		dragging = true
		set_process_input(true)

		if connected_socket:
			connected_socket.occupied = false
			connected_socket = null

func _input(event):
	if not dragging:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		dragging = false
		set_process_input(false)
		await get_tree().physics_frame
		try_connect()

func _process(_delta):
	if dragging:
		global_position = get_global_mouse_position()

func try_connect():
	var areas = get_overlapping_areas()

	for area in areas:
		if area.is_in_group("socket") and not area.occupied:
			global_position = Vector2(area.global_position.x + offset, area.global_position.y)
			connected_socket = area
			area.occupied = true
			emit_signal("connected", area)
			print(name + " connected")
			return

func tween_to_scale(target_scale: Vector2) -> void:
	if scale_tween != null:
		scale_tween.kill()

	scale_tween = create_tween()
	scale_tween.set_trans(Tween.TRANS_SINE)
	scale_tween.set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(self, "scale", target_scale, 0.1)

func _on_mouse_entered() -> void:
	tween_to_scale(hover_scale)

func _on_mouse_exited() -> void:
	if not dragging:
		tween_to_scale(normal_scale)
