extends Node

@onready var fade_scene: PackedScene = preload("res://Scenes/Menu/fade.tscn")

var fade_node: Node = null
var fade_animation: AnimationPlayer = null

var current_scene: Node = null
var overlay_scene: Node = null

var is_switching := false
var is_overlay_open := false

func _ready() -> void:
	var root := get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)

# ----------------------------
# NORMAL SCENE SWITCHING
# ----------------------------

func switch_scene(res_path: String, fade_in := true, fade_out := true) -> void:
	if is_switching or is_overlay_open:
		return
	call_deferred("_deferred_switch_scene", res_path, fade_in, fade_out)

func _deferred_switch_scene(res_path: String, fade_in := true, fade_out := true) -> void:
	is_switching = true

	if fade_out:
		await _fade_out_node(current_scene)

	if current_scene:
		current_scene.queue_free()

	var packed: PackedScene = load(res_path)
	if packed == null:
		push_error("Failed to load scene: " + res_path)
		is_switching = false
		return

	current_scene = packed.instantiate()
	get_tree().root.add_child(current_scene)
	get_tree().current_scene = current_scene

	if fade_in:
		await _fade_in_node(current_scene)

	is_switching = false

# ----------------------------
# OVERLAY SCENES
# ----------------------------

func open_overlay_scene(res_path: String, fade_in := true, fade_out := true) -> void:
	if is_switching or is_overlay_open:
		return
	call_deferred("_deferred_open_overlay_scene", res_path, fade_in, fade_out)

func _deferred_open_overlay_scene(res_path: String, fade_in := true, fade_out := true) -> void:
	is_switching = true

	if fade_out:
		await _fade_out_node(current_scene)

	_set_scene_frozen(current_scene, true)

	var packed: PackedScene = load(res_path)
	if packed == null:
		push_error("Failed to load overlay scene: " + res_path)
		_set_scene_frozen(current_scene, false)
		is_switching = false
		return

	overlay_scene = packed.instantiate()
	get_tree().root.add_child(overlay_scene)
	is_overlay_open = true

	if fade_in:
		await _fade_in_node(overlay_scene)

	is_switching = false

func close_overlay_scene(fade_in := true, fade_out := true) -> void:
	if is_switching or not is_overlay_open:
		return
	call_deferred("_deferred_close_overlay_scene", fade_in, fade_out)

func _deferred_close_overlay_scene(fade_in := true, fade_out := true) -> void:
	is_switching = true

	if fade_out:
		await _fade_out_node(overlay_scene)

	if overlay_scene:
		overlay_scene.queue_free()
		overlay_scene = null

	_set_scene_frozen(current_scene, false)
	is_overlay_open = false

	if fade_in:
		await _fade_in_node(current_scene)

	is_switching = false

# ----------------------------
# FADING
# ----------------------------

func _fade_out_node(target_node: Node) -> void:
	if target_node == null:
		return

	_create_fade_for_node(target_node)

	if fade_animation == null:
		push_error("Fade AnimationPlayer not found")
		return

	fade_animation.play("fade_out")
	await fade_animation.animation_finished

func _fade_in_node(target_node: Node) -> void:
	if target_node == null:
		return

	_create_fade_for_node(target_node)

	if fade_animation == null:
		push_error("Fade AnimationPlayer not found")
		return

	fade_animation.play("fade_in")
	await fade_animation.animation_finished

	if is_instance_valid(fade_node):
		fade_node.queue_free()
		fade_node = null
		fade_animation = null

func _create_fade_for_node(target_node: Node) -> void:
	if is_instance_valid(fade_node):
		fade_node.queue_free()

	fade_node = fade_scene.instantiate()
	target_node.add_child(fade_node)
	fade_animation = fade_node.get_node("AnimationPlayer")

# ----------------------------
# FREEZE / UNFREEZE CURRENT SCENE
# ----------------------------

func _set_scene_frozen(scene_root: Node, frozen: bool) -> void:
	if scene_root == null:
		return

	for child in scene_root.get_children():
		if child == fade_node:
			continue

		if frozen:
			child.process_mode = Node.PROCESS_MODE_DISABLED
		else:
			child.process_mode = Node.PROCESS_MODE_INHERIT
			
func close_overlay_and_switch_scene(res_path: String, fade_in := true, fade_out := true) -> void:
	if is_switching or not is_overlay_open:
		return
	call_deferred("_deferred_close_overlay_and_switch_scene", res_path, fade_in, fade_out)

func _deferred_close_overlay_and_switch_scene(res_path: String, fade_in := true, fade_out := true) -> void:
	is_switching = true

	if fade_out:
		await _fade_out_node(overlay_scene)

	if overlay_scene:
		overlay_scene.queue_free()
		overlay_scene = null

	_set_scene_frozen(current_scene, false)
	is_overlay_open = false

	if current_scene:
		current_scene.queue_free()

	var packed: PackedScene = load(res_path)
	if packed == null:
		push_error("Failed to load scene: " + res_path)
		is_switching = false
		return

	current_scene = packed.instantiate()
	get_tree().root.add_child(current_scene)
	get_tree().current_scene = current_scene

	if fade_in:
		await _fade_in_node(current_scene)

	is_switching = false
