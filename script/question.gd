@tool
extends Control

class_name Question

@export var question_text: String = ""

@onready var question_label: Label = $Label

func _ready() -> void:
	if question_text != "":
		question_label.text = question_text
	_set_up()
		
func _set_up():
	pass

func get_selected():
	return null
	
func is_answered() -> bool:
	return get_selected() != null
