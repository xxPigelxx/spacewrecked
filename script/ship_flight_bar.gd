extends TextureProgressBar

## Fortschrittsbalken der Flugdauer — Gegenstueck zur Health-Bar:
## fuellt sich von 0 bis 100, waehrend das Messfenster (run_duration) ablaeuft.
## Speist sich aus GameState.time_changed (seconds_left) statt aus der Health.
@export var fade_time := 0.5
## Sanftes Auf-und-Ab des Schiff-Icons ("fliegt"): Ausschlag in Pixeln + Dauer je Richtung.
@export var bob_amplitude := 4.0
@export var bob_duration := 0.8

## Kleines Schiff-Icon; bekommt per Tween eine leichte Flug-Wippe.
@onready var _marker: TextureRect = get_node_or_null("ShipMarker")

func _ready() -> void:
	max_value = 100.0
	value = 0.0
	GameState.phase_changed.connect(_check_phase)
	GameState.time_changed.connect(_update_time)
	# Startzustand ohne Animation setzen
	var in_journey := GameState.phase == GameState.Phase.JOURNEY
	visible = in_journey
	modulate.a = 1.0 if in_journey else 0.0
	_start_bob.call_deferred()

## Endlos-Tween: wippt das Icon sanft um seine (im Editor gesetzte) Ruheposition,
## ohne die Basisposition selbst zu veraendern.
func _start_bob() -> void:
	if not is_instance_valid(_marker):
		return
	var base_y := _marker.position.y
	var t := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_marker, "position:y", base_y - bob_amplitude, bob_duration)
	t.tween_property(_marker, "position:y", base_y, bob_duration)

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

## time_left sinkt von run_duration auf 0 — der Balken fuellt sich entsprechend auf.
func _update_time(time_left: float) -> void:
	var dur: float = GameState.run_duration
	if dur <= 0.0:
		value = 0.0
	else:
		value = clampf((dur - time_left) / dur * 100.0, 0.0, 100.0)
	_follow_fill()

## Nur die X-Position an die Fuellkante koppeln — Y bleibt dem Bob-Tween ueberlassen.
func _follow_fill() -> void:
	if not is_instance_valid(_marker):
		return
	var ratio: float = value / max_value if max_value > 0.0 else 0.0
	_marker.position.x = ratio * size.x - _marker.size.x * 0.5
