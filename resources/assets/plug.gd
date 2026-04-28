extends Area2D

@export var offset:= 0

var dragging := false
var connected_socket = null
var cable = null
signal connected(socket) 

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.pressed:
			dragging = true
			if connected_socket:
				connected_socket.occupied = false
				connected_socket = null
		else:
			dragging = false
			await get_tree().process_frame
			try_connect()

func _process(delta):
	if dragging:
		position = get_global_mouse_position()

func try_connect():
	var bodies = get_overlapping_areas()
	print(bodies)
	for body in bodies:
		if body.is_in_group("socket"):
			if not body.occupied:
				global_position.x = body.global_position.x + offset
				global_position.y = body.global_position.y 
				connected_socket = body
				body.occupied = true
				
				emit_signal("connected", body)
				print(name + " conected")
				break
