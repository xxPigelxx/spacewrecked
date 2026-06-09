extends TextureProgressBar

@export var fade_time := 0.5

func _ready() -> void:
	max_value = GameState.max_health
	value = GameState.health
	GameState.phase_changed.connect(_check_phase)
	GameState.health_changed.connect(_update_health)
	# Startzustand ohne Animation setzen
	var in_journey := GameState.phase == GameState.Phase.JOURNEY
	visible = in_journey
	modulate.a = 1.0 if in_journey else 0.0

func _check_phase(phase: int) -> void:
	if phase == GameState.Phase.JOURNEY:
		_fade_in()
	else:
		_fade_out()

func _fade_in() -> void:
	visible = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_time)

func _fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_time)
	tween.tween_callback(func(): visible = false)

func _update_health(new_health: float) -> void:
	value = new_health
