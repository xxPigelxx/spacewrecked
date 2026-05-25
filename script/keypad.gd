extends Interactable

@export var puzzle_id: String = "keypad1"
@export var code: String = "1234"
@onready var rich_text_label: RichTextLabel = $RichTextLabel

func _setup() -> void:
	rich_text_label.rotation = -get_parent().rotation

## Build overlay_data fresh at action time so door.gd's _ready() values are used.
func _action() -> void:
	SceneSwitcher.open_overlay_with_data(
		"res://Scenes/Number_pad.tscn",
		{"puzzle_id": puzzle_id, "code": code, "max_length": code.length()},
		true, false
	)
