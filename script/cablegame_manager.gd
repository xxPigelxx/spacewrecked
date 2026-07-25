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
	print("[CABLE] Puzzle offen: %s  phase=%s  stress=%s  sockets=%d" % [
		scene_file_path, GameState.phase, DyslexiaManager.stress, sockets.size()])

## TEMP DEBUG (Greif-Bug) — laeuft VOR GUI und Physics-Picking. Zeigt fuer jeden
## Linksklick, ob ein Control im Weg ist und ob das Picking ueberhaupt lebt.
## Zusammen mit den DBG-Bloecken in Draggable.gd wieder entfernen.
func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	var vp := get_viewport()
	print("[CLICK] maus=%s hovered=%s picking=%s paused=%s kabel=%d" % [
		vp.get_mouse_position(),
		str(vp.gui_get_hovered_control()),
		vp.physics_object_picking,
		get_tree().paused,
		spawned_cables.size()])

func _physics_process(_delta: float) -> void:
	if not win:
		_check_all_sockets_aktive()

func _check_all_sockets_aktive() -> void:
	for socket in sockets:
		if socket.aktive == false:
			return
	_on_win()

func _activate_socket_lamps():
	for socket in sockets:
		socket.activate_lamps()
		await get_tree().create_timer(0.05).timeout

func _on_win():
	_activate_socket_lamps()
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
