extends Control

@export var question_text: String = ""


@onready var checkboxes: Array[CheckBox] = [
	$"HBoxContainer/0",
	$"HBoxContainer/1",
	$"HBoxContainer/2",
	$"HBoxContainer/3",
	$"HBoxContainer/4",
	$"HBoxContainer/5",
]

@onready var question_label: Label = $Label
var selected :int = -1

func _ready() -> void:
	question_label.text = question_text
	for cb in checkboxes:
		cb.toggled.connect(_on_checkbox_toggled.bind(cb))

func _on_checkbox_toggled(pressed: bool, source: CheckBox) -> void:
	if pressed:
		selected = checkboxes.find(source)

func get_selected():
	return selected
