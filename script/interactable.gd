extends Area2D
class_name Interactable

@export var prompt_text := "Press E to interact"

## Optional: scene to open as overlay when interacted with.
@export_file("*.tscn") var overlay_scene: String = ""

## Optional: data to pass to the overlay scene via open_overlay_with_data.
## Set key/value pairs here matching the @export property names of the target scene.
## Example for mix game: { "leeway": 10.0, "require_full": true }
## Example for keypad:   { "puzzle_id": "door2", "code": "9876" }
@export var overlay_data: Dictionary = {}

@onready var label: RichTextLabel = get_node_or_null("RichTextLabel")

var player_near := false

func _ready() -> void:
	if label:
		label.visible = false
		label.text = ""
		label.bbcode_enabled = true
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
	_setup()
	
func _setup():
	pass
func _input(event: InputEvent) -> void:
	if player_near and event.is_action_pressed("interact"):
		_action()

func _action() -> void:
	if overlay_scene != "":
		SceneSwitcher.open_overlay_with_data(overlay_scene, overlay_data, true, false)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near = true
		if label:
			label.visible = true
			label.text = "[wave amp=20 freq=4]%s[/wave]" % prompt_text

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near = false
		if label:
			label.visible = false
			label.text = ""
