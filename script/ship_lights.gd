extends CanvasModulate

func _ready() -> void:
	GameState.ship_lights_changed.connect(switch_lights)
	visible = GameState.is_system_broken("strom")
	

func switch_lights(val):
	visible = !val
