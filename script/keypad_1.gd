extends Interactable


func _action() -> void:
	SceneSwitcher.open_overlay_scene("res://Scenes/Number_pad.tscn", true, false)
