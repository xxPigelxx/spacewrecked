extends Node

@export var max_cables := 5
@export var cable_spawn_y_offset := 80.0
@export var category:  = "strom"

@onready var error_code: Node2D = $ErrorCode
@onready var cable_spawn_marker: Marker2D = $CableSpawnMarker

## Wird von der Malfunction über open_overlay_with_data gesetzt (kann null sein bei Tutorial).
var malfunction = null

var sockets := []
var win := false

var cable := preload("res://Scenes/cable.tscn")
var spawned_cables := []

func _ready() -> void:
	sockets = get_tree().get_nodes_in_group("socket")

func _physics_process(_delta: float) -> void:
	if not win:
		_check_all_sockets_aktive()

func _check_all_sockets_aktive() -> void:
	for socket in sockets:
		if socket.aktive == false:
			return
	_on_win()

func _on_win():
	win = true
	error_code.lamp_flash()
	AudioManager.play_success()
	await get_tree().create_timer(0.75).timeout
	if malfunction:
		malfunction.mark_solved()
	SceneSwitcher.close_overlay_scene()
		
func spawn_cable() -> void:
	var new_cable = cable.instantiate()
	$"Cabels".add_child(new_cable)
	new_cable.global_position = cable_spawn_marker.global_position + Vector2(0, -spawned_cables.size() * cable_spawn_y_offset)
	spawned_cables.append(new_cable)

func _on_button_pressed() -> void:
	if spawned_cables.size() < max_cables:
		spawn_cable()


func _on_return_bt_pressed() -> void:
	SceneSwitcher.close_overlay_scene()
