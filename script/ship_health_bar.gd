extends TextureProgressBar

@export var fade_time := 0.5

## Herzschlag des Herz-Icons: Ruhe- und Maximal-Rate (Schlaege/Sekunde) und
## Puls-Staerke (Scale-Ausschlag). Skaliert mit sinkender Gesundheit —
## wenig Leben = schnellerer + staerkerer Herzschlag, volles Leben = ruhiger Beat.
@export var idle_beats_per_sec := 1.0
@export var max_beats_per_sec := 3.0
@export var idle_pulse := 0.06
@export var max_pulse := 0.22

## Herz-Icon: folgt der Fuellkante (X, wie der ShipMarker der Flight-Bar) und
## pulst wie ein Herzschlag (Scale) statt zu wippen.
@onready var _marker: TextureRect = get_node_or_null("ShipHealthMarker")
var _pulse_phase := 0.0

func _ready() -> void:
	max_value = GameState.max_health
	value = GameState.health
	GameState.phase_changed.connect(_check_phase)
	GameState.health_changed.connect(_update_health)
	# Startzustand ohne Animation setzen
	var in_journey := GameState.phase == GameState.Phase.JOURNEY
	visible = in_journey
	modulate.a = 1.0 if in_journey else 0.0
	_follow_fill.call_deferred()

## Herzschlag: Tempo und Staerke aus der Gesundheit ableiten und das Icon pulsen.
func _process(delta: float) -> void:
	if not is_instance_valid(_marker):
		return
	if not visible or GameState.phase != GameState.Phase.JOURNEY:
		_marker.scale = Vector2.ONE
		return
	# 0 = volles Leben, 1 = fast tot -> treibt Tempo & Staerke.
	var intensity: float = clampf(1.0 - value / max_value, 0.0, 1.0) if max_value > 0.0 else 0.0
	var rate: float = lerpf(idle_beats_per_sec, max_beats_per_sec, intensity)
	var amp: float = lerpf(idle_pulse, max_pulse, intensity)
	_pulse_phase += delta * rate * TAU
	# 0..1-Puls (Herz wird nur groesser, nie kleiner), Skalierung um die Mitte.
	var beat: float = sin(_pulse_phase) * 0.5 + 0.5
	_marker.pivot_offset = _marker.size * 0.5
	var s: float = 1.0 + beat * amp
	_marker.scale = Vector2(s, s)

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
	_follow_fill()

## X-Position des Herzens an die Fuellkante koppeln (Y bleibt zentriert).
func _follow_fill() -> void:
	if not is_instance_valid(_marker):
		return
	var ratio: float = value / max_value if max_value > 0.0 else 0.0
	_marker.position.x = ratio * size.x - _marker.size.x * 0.5
