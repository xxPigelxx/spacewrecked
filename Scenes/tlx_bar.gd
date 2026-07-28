extends Question

@onready var h_slider: HSlider = $HBoxContainer/HSlider
@onready var label: Label = $HBoxContainer/HSlider/Label
@onready var erklärung_label: Label = $HBoxContainer/Control/Explain

@export var erklärung: String = ""

var _has_answered := false


func _set_up():
	if erklärung != "":
		erklärung_label.text = erklärung
	label.text = "?"
	h_slider.modulate = Color(1, 1, 1, 0.5)

func get_selected():
	return h_slider.value if _has_answered else null

func is_answered() -> bool:
	return _has_answered


func _on_h_slider_value_changed(value: float) -> void:
	label.text = str(int(value))
	h_slider.modulate = Color(1, 1, 1, 1)
	_has_answered = true
