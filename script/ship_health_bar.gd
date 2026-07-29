extends TextureProgressBar

@export var fade_time := 0.5
## Wie lange ein Tutorial-Schritt zum Auffuellen braucht (Sekunden, 0 = sofort).
@export var fill_time := 0.6

@export_group("Herzschlag")
## Schlaege pro Sekunde bei vollem bzw. leerem Leben.
@export var idle_beats_per_sec := 0.9
@export var max_beats_per_sec := 2.0
## Verlauf zwischen den beiden Werten, ueber den Schaden (0 = voll, 1 = leer).
## Ohne Curve steigt das Tempo linear — mit Curve laesst sich einstellen, ab
## wann es hektisch wird (z.B. lange ruhig, erst kurz vor Schluss steil hoch).
@export var beat_rate_curve: Curve
## Wie stark das Herz-Icon beim Schlag aufgeht.
@export var pulse_scale := 0.15
## Aus, wenn dieselbe Leiste mehrfach in einer Szene haengt: nur eine Instanz
## darf den Ton spielen, sonst schlaegt das Herz doppelt. Das Icon pulst
## weiterhin, die Leiste bleibt also vollstaendig sichtbar.
@export var play_sound := true
## Ab welchem Lebensstand der Ton einsetzt (Anteil, 1.0 = volles Leben).
## Darueber pulst das Icon stumm weiter. 1.0 = von Anfang an hoerbar.
@export_range(0.0, 1.0, 0.05) var sound_below_health := 0.75
## Lautstaerke beim Einsetzen und bei leerem Leben (dB). Dazwischen fuehrt
## dieselbe Curve wie beim Tempo. Beide Werte gelten absolut und ersetzen das
## volume_db des Players in der Szene.
@export_range(-40.0, 6.0, 1.0) var start_volume_db := -12.0
@export_range(-40.0, 6.0, 1.0) var max_volume_db := 0.0
## Nur zum Testen: laesst den Herzschlag in jeder Phase laufen und fuellt die
## Leiste ohne Weichzeichnen, damit sich die Curve mit dem Debug-Regler pruefen
## laesst, ohne eine Journey zu starten. Fuer die Studie aus.
@export var debug_always_beat := false
const HEARTBEAT_SFX := "res://resources/assets/sfx/universfield-heartbeat-single-383748.mp3"
# Das Sample (1.13 s) ist laenger als der kuerzeste Takt (0.5 s bei 2 Schlaegen
# pro Sekunde). Mit nur einem Player schneidet jeder Schlag den vorigen ab,
# deshalb reihum mehrere: Sample geteilt durch kuerzesten Takt, aufgerundet.
const HEARTBEAT_VOICES := 3

# Anteile eines Takts fuer Aufgehen und Zurueckgehen des Icons. Als Anteil und
# nicht in Sekunden, damit der Schlag bei hohem Tempo mitzieht statt zu
# verschmieren; der Rest des Takts ist Pause.
const PULSE_RISE_RATIO := 0.15
const PULSE_FALL_RATIO := 0.30

## Herz-Icon: folgt der Fuellkante (X, wie der ShipMarker der Flight-Bar) und
## pulst wie ein Herzschlag (Scale) statt zu wippen.
@onready var _marker: TextureRect = get_node_or_null("ShipHealthMarker")
@onready var  _heart_player: AudioStreamPlayer = $HeartBeatPlayer

var _fill_tween: Tween = null
var _beat_tween: Tween = null
var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0


func _ready() -> void:
	max_value = GameState.max_health
	value = GameState.health
	GameState.phase_changed.connect(_check_phase)
	GameState.health_changed.connect(_update_health)
	if ResourceLoader.exists(HEARTBEAT_SFX):
		_heart_player.stream = load(HEARTBEAT_SFX)
	_build_voices()

	# Die Leiste ist schon im Tutorial da — dort leer, und fuellt sich mit jeder
	# Reparatur. Erst in den Ergebnissen verschwindet sie.
	var shown := GameState.phase != GameState.Phase.RESULTS
	visible = shown
	modulate.a = 1.0 if shown else 0.0
	_check_phase(GameState.phase)
	_follow_fill.call_deferred()

## Der Player aus der Szene plus Kopien daneben. Die Kopien uebernehmen Stream
## und Bus; die Lautstaerke setzt _play_beat_sound() ohnehin bei jedem Schlag.
func _build_voices() -> void:
	_voices.append(_heart_player)
	for i in HEARTBEAT_VOICES - 1:
		var extra := AudioStreamPlayer.new()
		extra.stream = _heart_player.stream
		extra.bus = _heart_player.bus
		_heart_player.add_sibling(extra)
		_voices.append(extra)

## Reihum den naechsten Player nehmen, statt denselben neu zu starten — so klingt
## der vorige Schlag zu Ende, waehrend der naechste schon anschlaegt.
## weight ist derselbe Curve-Wert wie beim Tempo: leise beim Einsetzen, bei
## leerem Leben max_volume_db.
func _play_beat_sound(weight: float) -> void:
	var player: AudioStreamPlayer = _voices[_next_voice]
	if player.stream == null:
		return
	player.volume_db = lerpf(start_volume_db, max_volume_db, weight)
	player.play(0.0)
	_next_voice = (_next_voice + 1) % _voices.size()

func _check_phase(phase: int) -> void:
	var beating: bool = phase == GameState.Phase.JOURNEY or debug_always_beat
	if is_instance_valid(_marker):
		# Das Herz gehoert zum Herzschlag — und der laeuft erst ab der Journey.
		_marker.visible = beating
	if phase == GameState.Phase.RESULTS:
		_fade_out()
	else:
		_fade_in()

	if beating:
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
	if (GameState.phase != GameState.Phase.JOURNEY and not debug_always_beat) or not is_instance_valid(_marker):
		_beat_tween = null
		return

	var damage: float = clampf(1.0 - value / max_value, 0.0, 1.0) if max_value > 0.0 else 0.0
	# Geklemmt, damit ein Curve-Wertebereich ausserhalb 0..1 nicht zu absurden
	# (oder negativen) Taktlaengen fuehrt.
	var weight: float = clampf(beat_rate_curve.sample_baked(damage), 0.0, 1.0) if beat_rate_curve else damage
	var interval: float = 1.0 / lerpf(idle_beats_per_sec, max_beats_per_sec, weight)

	# Der Takt laeuft immer (das Icon pulst also von Anfang an), hoerbar wird er
	# erst ab dem Schwellwert — sonst tickt es die ganze Runde durch und der
	# Herzschlag verliert genau die Bedeutung, die er tragen soll.
	if play_sound and 1.0 - damage <= sound_below_health:
		_play_beat_sound(weight)

	_marker.pivot_offset = _marker.size * 0.5
	_beat_tween = create_tween()
	_beat_tween.tween_property(_marker, "scale", Vector2.ONE * (1.0 + pulse_scale), interval * PULSE_RISE_RATIO)
	_beat_tween.tween_property(_marker, "scale", Vector2.ONE, interval * PULSE_FALL_RATIO)
	_beat_tween.tween_interval(interval * (1.0 - PULSE_RISE_RATIO - PULSE_FALL_RATIO))
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
	# Beim Testen direkt setzen: sonst haengt die Leiste dem Regler um fill_time
	# hinterher und man zieht gegen einen Tween, der staendig neu startet.
	if GameState.phase == GameState.Phase.SETUP and fill_time > 0.0 and not debug_always_beat:
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
