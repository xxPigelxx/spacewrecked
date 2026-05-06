extends Node2D

@onready var plug_a: CharacterBody2D = $PlugA
@onready var plug_b: CharacterBody2D = $PlugB
@onready var plug_a_point: Marker2D = $PlugA/CablePoint
@onready var plug_b_point: Marker2D = $PlugB/CablePoint
@onready var cable: Line2D = $Line

var conected_sockets := []

func _ready() -> void:
	update_cable()

func _process(_delta: float) -> void:
	if plug_a.dragging or plug_b.dragging:
		update_cable()
	
func update_cable() -> void:
	var start = cable.to_local(plug_a_point.global_position)
	var end = cable.to_local(plug_b_point.global_position)
	cable.points = PackedVector2Array([start, end])

func _check_conected_sockets() -> bool:
	for socket in conected_sockets:
		socket.aktive = false
		
	if conected_sockets.size() != 2:
		return false

	var a = conected_sockets[0]
	var b = conected_sockets[1]

	if a.pair_id == b.pair_id:
		a.aktive = true
		b.aktive = true
		return true

	return false

func add_socket(socket):
	if socket not in conected_sockets:
		conected_sockets.append(socket)
	_check_conected_sockets()

func remove_socket(socket):
	socket.aktive = false
	conected_sockets.erase(socket)
	_check_conected_sockets()
