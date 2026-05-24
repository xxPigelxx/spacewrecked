extends CanvasModulate

func _ready() -> void:
	GameState.ship_lights_changed.connect(switch_lights)
	

func switch_lights(val):
	visible = !val
