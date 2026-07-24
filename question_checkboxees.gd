extends Question

enum ScaleType { AGREEMENT, QUALITY, FREQUENCY }

@export var scale_type: ScaleType = ScaleType.AGREEMENT

const SCALE_LABELS := {
	ScaleType.AGREEMENT: ["stimme gar nicht zu", "stimme voll zu"],
	ScaleType.QUALITY:   ["gar nicht", "sehr gut"],
	ScaleType.FREQUENCY: ["keine", "sehr viel"],
}

@onready var checkboxes: Array[CheckBox] = [
	$"HBoxContainer/1",
	$"HBoxContainer/2",
	$"HBoxContainer/3",
	$"HBoxContainer/4",
	$"HBoxContainer/5",
]
@onready var end_label_links: Label = $HBoxContainer/EndLabelLinks
@onready var end_label_rechts: Label = $HBoxContainer/EndLabelRechts


var selected :int = -1

func _set_up():
	for cb in checkboxes:
		cb.toggled.connect(_on_checkbox_toggled.bind(cb))
	var labels: Array = SCALE_LABELS[scale_type]
	end_label_links.text = labels[0]
	end_label_rechts.text = labels[1]

func _on_checkbox_toggled(pressed: bool, source: CheckBox) -> void:
	if pressed:
		selected = int(source.name)

func get_selected():
	return selected

func is_answered() -> bool:
	return selected != -1
