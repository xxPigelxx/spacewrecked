extends Interactable

@onready var manual: CanvasLayer = $"../../Manual"
@onready var point_light_2d: PointLight2D = $PointLight2D
var lights_size
var light_tween_ratio = Vector2(0.2,0.2)

func _action() -> void:
	manual.activate("Home")
	GameState.manule_aquiered = true
	queue_free()

func _setup() -> void:
	lights_size = point_light_2d.scale
	
	var tween = create_tween()
	tween.set_loops()

	tween.tween_property(point_light_2d, "scale", lights_size - light_tween_ratio, 0.3) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(point_light_2d, "scale", lights_size + light_tween_ratio, 0.1) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)
