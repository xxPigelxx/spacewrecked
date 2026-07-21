extends Question

@onready var checkboxes: Array[CheckBox] = [
	$"HBoxContainer/0",
	$"HBoxContainer/1",
	$"HBoxContainer/2",
	$"HBoxContainer/3",
	$"HBoxContainer/4",
	$"HBoxContainer/5",
]

var selected :int = -1

func _set_up():
	for cb in checkboxes:
		cb.toggled.connect(_on_checkbox_toggled.bind(cb))

func _on_checkbox_toggled(pressed: bool, source: CheckBox) -> void:
	if pressed:
		selected = checkboxes.find(source)
		print(selected)

func get_selected():
	return selected

func is_answered() -> bool:
	return selected != -1
