@tool
extends Question

@export var musst_anwnser:= true

@onready var edit: TextEdit = $Edit

func get_selected():
	return edit.text

func is_answered() -> bool:
	if musst_anwnser:
		return edit.text.strip_edges() != ""
	return true
