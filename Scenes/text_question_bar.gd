extends Control

@export var question_text: String = ""

@onready var edit: TextEdit = $Edit
@onready var question_label: Label = $Label

func _ready() -> void:
	if question_text != "":
		question_label.text = question_text

func get_selected():
	return edit.text
