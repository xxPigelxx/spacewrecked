extends Question

@onready var option_button: OptionButton = $OptionButton

func get_selected():
	var idx := option_button.selected
	return option_button.get_item_text(idx) if idx >= 0 else ""

func is_answered() -> bool:
	return option_button.selected != -1
