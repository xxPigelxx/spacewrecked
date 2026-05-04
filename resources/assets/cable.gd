extends Node2D

@export var cable_color: Color
@export var collision_width := 24.0

@onready var plug_a: Area2D = $PlugAArea
@onready var plug_b: Area2D = $PlugBArea
@onready var plug_a_point: Marker2D = $PlugAArea/CablePoint
@onready var plug_b_point: Marker2D = $PlugBArea/CablePoint
@onready var cable: Area2D = $Cable
@onready var line: Line2D = $Cable/Line
@onready var line_collision: CollisionPolygon2D = $Cable/LineCollision

var dragging_cable := false
var drag_offset := Vector2.ZERO

func _ready():
	plug_a.cable = self
	plug_b.cable = self
	plug_a.connected.connect(_on_plug_connected)
	plug_b.connected.connect(_on_plug_connected)
	cable.input_event.connect(_on_grab_area_input_event)

	line.default_color = cable_color
	line.width = 10.0

	await get_tree().process_frame
	update_cable()

func _process(_delta):
	if dragging_cable:
		global_position = get_global_mouse_position() + drag_offset
		update_cable()

	if plug_a.dragging or plug_b.dragging:
		update_cable()

func update_cable():
	var start = cable.to_local(plug_a_point.global_position)
	var end = cable.to_local(plug_b_point.global_position)

	var points: Array[Vector2] = []
	var segment_count := 20

	for i in range(segment_count + 1):
		var t = i / float(segment_count)
		var pos = start.lerp(end, t)
		var sag = sin(t * PI) * start.distance_to(end) * 0.1
		pos.y += sag
		points.append(pos)

	line.points = PackedVector2Array(points)
	_update_collision_polygon(points)

func _update_collision_polygon(points: Array[Vector2]) -> void:
	if points.size() < 2:
		return

	var left_side: Array[Vector2] = []
	var right_side: Array[Vector2] = []
	var half_width := collision_width * 0.5

	for i in range(points.size()):
		var dir: Vector2

		if i == 0:
			dir = (points[i + 1] - points[i]).normalized()
		elif i == points.size() - 1:
			dir = (points[i] - points[i - 1]).normalized()
		else:
			dir = (points[i + 1] - points[i - 1]).normalized()

		var normal = Vector2(-dir.y, dir.x)
		left_side.append(points[i] + normal * half_width)
		right_side.append(points[i] - normal * half_width)

	right_side.reverse()

	var polygon_points: Array[Vector2] = []
	polygon_points.append_array(left_side)
	polygon_points.append_array(right_side)

	line_collision.polygon = PackedVector2Array(polygon_points)

func _input(event):
	if dragging_cable and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		dragging_cable = false

func _on_grab_area_input_event(_viewport, event, _shape_idx):
	if plug_a.dragging or plug_b.dragging:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		dragging_cable = true
		drag_offset = global_position - get_global_mouse_position()

func _on_plug_connected(_socket):
	update_cable()
