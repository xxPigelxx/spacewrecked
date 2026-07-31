extends VSlider
@onready var label_2: Label = $Label2




func _ready() -> void:
	value = GameState.run_duration
	_update_lable()




func _on_drag_ended(value_changed: bool) -> void:
	if value_changed:
		GameState.run_duration = value
	_update_lable()
	
func _update_lable():
	label_2.text = str(value)
