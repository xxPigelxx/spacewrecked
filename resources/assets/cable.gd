extends Node2D

@export var cable_color: Color

@onready var plug_a: Area2D = $PlugAArea
@onready var plug_b: Area2D = $PlugBArea
@onready var plug_a_point: Marker2D = $PlugAArea/CablePoint
@onready var plug_b_point: Marker2D = $PlugBArea/CablePoint
@onready var line: Line2D = $Line



func _ready():
	plug_a.cable = self
	plug_b.cable = self
	plug_a.connected.connect(_on_plug_connected)
	plug_b.connected.connect(_on_plug_connected)
	await get_tree().process_frame
	update_cable()
	
func _process(delta):
	if plug_a.dragging or plug_b.dragging :
		update_cable()

func update_cable():
	var start = to_local(plug_a_point.global_position)
	var end = to_local(plug_b_point.global_position)

	var points = []
	var segment_count = 20

	for i in range(segment_count + 1):
		var t = i / float(segment_count)
		var pos = start.lerp(end, t)

		var sag = sin(t * PI) * start.distance_to(end) * 0.1
		pos.y += sag

		points.append(pos)

	line.points = points
func _on_plug_connected(socket):
	update_cable()
