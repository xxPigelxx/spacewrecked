extends Question

@onready var h_slider: HSlider = $HSlider
@onready var label: Label = $HBoxContainer/HSlider/Label


func get_selected():
	return h_slider.value

func is_answered() -> bool:
	return true


func _on_h_slider_value_changed(value: float) -> void:
	label.text = str(int(value))
