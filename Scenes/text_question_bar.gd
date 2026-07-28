@tool
extends Question

@onready var edit: TextEdit = $Edit

func get_selected():
	return edit.text

func is_answered() -> bool:
	return edit.text.strip_edges() != ""
