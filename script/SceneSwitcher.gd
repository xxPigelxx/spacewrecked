extends Node

@onready var fade_scene: PackedScene = preload("res://Scenes/Menu/fade.tscn")

var fade_node: Node = null
var fade_animation: AnimationPlayer = null
var _manual_was_visible := false
var _last_freeze_manual := false

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

## Wechselt zur Szene, egal was gerade offen ist — schliesst ein offenes Overlay
## mit und wartet einen laufenden Uebergang ab, statt den Aufruf zu verwerfen.
##
## switch_scene() steigt bei offenem Overlay wortlos aus. Fuer normale
## Navigation ist das richtig, aber wenn der Lauf endet (Leben leer oder Zeit um)
## waehrend ein Raetsel offen ist, bliebe der Endscreen sonst aus und die
## Versuchsperson haengt im Raetsel fest.
func force_switch_scene(res_path: String, fade_in := true, fade_out := true) -> void:
	while is_switching:
		await get_tree().process_frame
	if is_overlay_open:
		close_overlay_and_switch_scene(res_path, fade_in, fade_out)
	else:
		switch_scene(res_path, fade_in, fade_out)

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

func open_overlay_scene(res_path: String, fade_in := true, fade_out := true, freeze_manual := false) -> void:
	if is_switching or is_overlay_open:
		return
	call_deferred("_deferred_open_overlay_scene", res_path, fade_in, fade_out, freeze_manual)

func _deferred_open_overlay_scene(res_path: String, fade_in := true, fade_out := true, freeze_manual := false) -> void:
	is_switching = true

	if fade_out:
		await _fade_out_node(current_scene)

	_set_scene_frozen(current_scene, true, freeze_manual)
	_last_freeze_manual = freeze_manual

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

# ----------------------------
# OVERLAY WITH DATA
# ----------------------------
## Opens an overlay and calls setup(data) on its root node before showing it.
## Use this to pass recipes, configs, etc. to a freshly loaded scene.
## Example:
##   SceneSwitcher.open_overlay_with_data(
##     "res://Scenes/Puzzle/mix_Game.tscn",
##     {
##       "recipe": [{"bottle_name":"Wasser","target_ml":50.0}],
##       "leeway": 10.0,
##       "require_full": true
##     }
##   )
func open_overlay_with_data(res_path: String, data: Dictionary, fade_in := true, fade_out := true, freeze_manual := false) -> void:
	if is_switching or is_overlay_open:
		return
	call_deferred("_deferred_open_overlay_with_data", res_path, data, fade_in, fade_out, freeze_manual)

func _deferred_open_overlay_with_data(res_path: String, data: Dictionary, fade_in := true, fade_out := true, freeze_manual := false) -> void:
	is_switching = true

	if fade_out:
		await _fade_out_node(current_scene)

	_set_scene_frozen(current_scene, true, freeze_manual)
	_last_freeze_manual = freeze_manual

	var packed: PackedScene = load(res_path)
	if packed == null:
		push_error("Failed to load overlay scene: " + res_path)
		_set_scene_frozen(current_scene, false)
		is_switching = false
		return

	overlay_scene = packed.instantiate()

	# Apply every key in data directly as a property on the root node
	for key in data.keys():
		if key in overlay_scene:
			overlay_scene.set(key, data[key])
		else:
			push_warning("SceneSwitcher.open_overlay_with_data: property '" + key + "' not found on " + res_path)

	get_tree().root.add_child(overlay_scene)
	is_overlay_open = true

	if fade_in:
		await _fade_in_node(overlay_scene)

	is_switching = false

func _deferred_close_overlay_scene(fade_in := true, fade_out := true) -> void:
	is_switching = true

	if fade_out:
		await _fade_out_node(overlay_scene)

	if overlay_scene:
		overlay_scene.queue_free()
		overlay_scene = null

	_set_scene_frozen(current_scene, false, _last_freeze_manual)
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

func _set_scene_frozen(scene_root: Node, frozen: bool, freeze_manual := true) -> void:
	if scene_root == null:
		return

	for child in scene_root.get_children():
		if child == fade_node:
			continue
		if freeze_manual and child.is_in_group("no_freeze"):
			if frozen:
				_manual_was_visible = child.visible
				child.visible = false
			else:
				child.visible = _manual_was_visible
			continue
		if not freeze_manual and child.is_in_group("no_freeze"):
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

	_set_scene_frozen(current_scene, false, _last_freeze_manual)
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
