extends TextureProgressBar

@export var fade_time := 0.5
## Wie lange ein Tutorial-Schritt zum Auffuellen braucht (Sekunden, 0 = sofort).
@export var fill_time := 0.6

@export_group("Herzschlag")
## Schlaege pro Sekunde bei vollem bzw. leerem Leben.
@export var idle_beats_per_sec := 0.9
@export var max_beats_per_sec := 2.0
## Wie stark das Herz-Icon beim Schlag aufgeht.
@export var pulse_scale := 0.15
const HEARTBEAT_SFX := "res://resources/assets/sfx/universfield-heartbeat-single-383748.mp3"

## Herz-Icon: folgt der Fuellkante (X, wie der ShipMarker der Flight-Bar) und
## pulst wie ein Herzschlag (Scale) statt zu wippen.
@onready var _marker: TextureRect = get_node_or_null("ShipHealthMarker")
@onready var  _heart_player: AudioStreamPlayer = $HeartBeatPlayer

var _fill_tween: Tween = null
var _beat_tween: Tween = null


func _ready() -> void:
	max_value = GameState.max_health
	value = GameState.health
	GameState.phase_changed.connect(_check_phase)
	GameState.health_changed.connect(_update_health)
	if ResourceLoader.exists(HEARTBEAT_SFX):
		_heart_player.stream = load(HEARTBEAT_SFX)

	# Die Leiste ist schon im Tutorial da — dort leer, und fuellt sich mit jeder
	# Reparatur. Erst in den Ergebnissen verschwindet sie.
	var shown := GameState.phase != GameState.Phase.RESULTS
	visible = shown
	modulate.a = 1.0 if shown else 0.0
	_check_phase(GameState.phase)
	_follow_fill.call_deferred()

func _check_phase(phase: int) -> void:
	var in_journey: bool = phase == GameState.Phase.JOURNEY
	if is_instance_valid(_marker):
		# Das Herz gehoert zum Herzschlag — und der laeuft erst ab der Journey.
		_marker.visible = in_journey
	if phase == GameState.Phase.RESULTS:
		_fade_out()
	else:
		_fade_in()

	if in_journey:
		if _beat_tween == null:
			_beat()
	elif _beat_tween != null:
		_beat_tween.kill()
		_beat_tween = null
		if is_instance_valid(_marker):
			_marker.scale = Vector2.ONE

## Ein Schlag: Ton anspielen, Icon auf und zu, Rest des Takts warten, wiederholen.
## Tempo kommt aus dem Lebensstand und wird bei jedem Schlag neu bestimmt.
func _beat() -> void:
	if GameState.phase != GameState.Phase.JOURNEY or not is_instance_valid(_marker):
		_beat_tween = null
		return

	var damage: float = clampf(1.0 - value / max_value, 0.0, 1.0) if max_value > 0.0 else 0.0
	var interval: float = 1.0 / lerpf(idle_beats_per_sec, max_beats_per_sec, damage)

	if _heart_player.stream != null:
		_heart_player.play(0.0)

	_marker.pivot_offset = _marker.size * 0.5
	_beat_tween = create_tween()
	_beat_tween.tween_property(_marker, "scale", Vector2.ONE * (1.0 + pulse_scale), 0.10)
	_beat_tween.tween_property(_marker, "scale", Vector2.ONE, 0.20)
	_beat_tween.tween_interval(maxf(interval - 0.30, 0.0))
	_beat_tween.tween_callback(_beat)

func _fade_in() -> void:
	visible = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_time)

func _fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_time)
	tween.tween_callback(func(): visible = false)

## Im Tutorial kommt die Gesundheit in vier grossen Spruengen — die werden weich
## aufgefuellt. In der Journey aendert sie sich durch den Drain jeden Frame, dort
## wird direkt gesetzt (sonst entstuende pro Frame ein neuer Tween).
func _update_health(new_health: float) -> void:
	if _fill_tween and _fill_tween.is_valid():
		_fill_tween.kill()
	if GameState.phase == GameState.Phase.SETUP and fill_time > 0.0:
		_fill_tween = create_tween()
		_fill_tween.tween_method(_set_bar_value, value, new_health, fill_time)
	else:
		_set_bar_value(new_health)

func _set_bar_value(v: float) -> void:
	value = v
	_follow_fill()

## X-Position des Herzens an die Fuellkante koppeln (Y bleibt zentriert).
func _follow_fill() -> void:
	if not is_instance_valid(_marker):
		return
	var ratio: float = value / max_value if max_value > 0.0 else 0.0
	_marker.position.x = ratio * size.x - _marker.size.x * 0.5
