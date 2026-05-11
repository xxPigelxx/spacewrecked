# CablePlug.gd
extends Draggable

@export var offset := 0.0
@onready var cable: Node2D = $".."

var connected_socket = null


func _on_drag_started() -> void:
	if connected_socket:
		cable.remove_socket(connected_socket)
		connected_socket.occupied = false
		connected_socket = null

func _on_drag_ended() -> void:
	try_connect()

func try_connect() -> void:
	var areas = area.get_overlapping_areas()

	for socket in areas:
		if socket.is_in_group("socket") and not socket.occupied:
			global_position = Vector2(socket.global_position.x + offset, socket.global_position.y)
			connected_socket = socket
			socket.occupied = true
			cable.add_socket(socket)
			cable.update_cable()
			print(name + " connected to " + socket.pair_id)
			return
