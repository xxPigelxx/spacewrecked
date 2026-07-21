extends TextureProgressBar

@export var fade_time := 0.5
## Wie lange ein Tutorial-Schritt zum Auffuellen braucht (Sekunden, 0 = sofort).
@export var fill_time := 0.6

@export_group("Herzschlag")
## Schlaege pro Sekunde bei vollem bzw. fast leerem Leben.
## 2.0/s = 120 bpm — darueber klingt es nach Panik statt nach Anspannung.
@export var idle_beats_per_sec := 0.9
@export var max_beats_per_sec := 2.0
## Puls-Staerke des Herz-Icons (Scale-Ausschlag) bei vollem bzw. leerem Leben.
@export var idle_pulse := 0.06
@export var max_pulse := 0.22
## Ab welchem LEBENSSTAND wird der Schlag hoerbar — dieselbe Skala wie die
## Leiste und max_health, also direkt ablesbar statt in Schaden umgerechnet.
## Achtung beim Herabsetzen: bei 0.4 Leben/s Verfall braucht 65 rund 88 s, und
## jede Reparatur gibt 20 (= 50 s) zurueck. Zu niedrig = nie hoerbar.
@export var heartbeat_below_health := 65.0
## Lautstaerke an der Hoerschwelle bzw. bei leerem Leben.
@export var heartbeat_min_db := -18.0
@export var heartbeat_max_db := -4.0
## Ton abschaltbar — das Icon pulst unabhaengig davon weiter.
@export var heartbeat_audio_enabled := true

const HEARTBEAT_SFX := "res://resources/assets/sfx/universfield-heartbeat-single-383748.mp3"

## Herz-Icon: folgt der Fuellkante (X, wie der ShipMarker der Flight-Bar) und
## pulst wie ein Herzschlag (Scale) statt zu wippen.
@onready var _marker: TextureRect = get_node_or_null("ShipHealthMarker")

var _fill_tween: Tween = null
## Der Puls ist eine Tween-Kette, die sich am Ende selbst neu plant. Tempo und
## Staerke werden bei jedem Schlag frisch aus dem Lebensstand berechnet — es
## braucht also kein _process, und der Ton haengt direkt am Ausschlag.
var _beat_tween: Tween = null
## Eigener Player statt des geteilten SFX-Pools: der haelt nur 8 Plaetze und
## waere bei 2 Schlaegen/s sofort belegt.
var _heart_player: AudioStreamPlayer = null

func _ready() -> void:
	max_value = GameState.max_health
	value = GameState.health
	GameState.phase_changed.connect(_check_phase)
	GameState.health_changed.connect(_update_health)

	_heart_player = AudioStreamPlayer.new()
	_heart_player.bus = "sfx"
	add_child(_heart_player)
	if ResourceLoader.exists(HEARTBEAT_SFX):
		_heart_player.stream = load(HEARTBEAT_SFX)

	# Startzustand ohne Animation setzen. Die Leiste ist schon im Tutorial da —
	# dort leer, und fuellt sich mit jeder Reparatur. Erst in den Ergebnissen
	# verschwindet sie.
	var shown := GameState.phase != GameState.Phase.RESULTS
	visible = shown
	modulate.a = 1.0 if shown else 0.0
	_update_marker_visibility()
	_follow_fill.call_deferred()
	_update_beating()

func _check_phase(phase: int) -> void:
	_update_marker_visibility()
	if phase == GameState.Phase.RESULTS:
		_fade_out()
	else:
		_fade_in()
	_update_beating()

## Das Herz gehoert zum Herzschlag — und der laeuft erst ab der Journey.
## Im Tutorial ist die Leiste da, aber ohne pochendes Herz.
func _update_marker_visibility() -> void:
	if is_instance_valid(_marker):
		_marker.visible = GameState.phase == GameState.Phase.JOURNEY

# ---------------------------------------------------------------------------
# HERZSCHLAG
# ---------------------------------------------------------------------------

func _update_beating() -> void:
	if GameState.phase == GameState.Phase.JOURNEY and is_instance_valid(_marker):
		if _beat_tween == null:
			_beat_once()
	else:
		_stop_beating()

func _stop_beating() -> void:
	if _beat_tween and _beat_tween.is_valid():
		_beat_tween.kill()
	_beat_tween = null
	if is_instance_valid(_marker):
		_marker.scale = Vector2.ONE

## Ein Schlag: Ton anspielen, Icon kurz aufgehen und zurueck, den Rest des
## Intervalls warten, dann sich selbst erneut aufrufen.
func _beat_once() -> void:
	if not is_instance_valid(_marker) or GameState.phase != GameState.Phase.JOURNEY:
		_stop_beating()
		return

	# 0 = volles Leben, 1 = fast tot -> treibt Tempo und Puls-Staerke.
	var intensity: float = clampf(1.0 - value / max_value, 0.0, 1.0) if max_value > 0.0 else 0.0
	var interval: float = 1.0 / maxf(lerpf(idle_beats_per_sec, max_beats_per_sec, intensity), 0.05)
	var amp: float = lerpf(idle_pulse, max_pulse, intensity)

	_play_heartbeat()

	# Anschlag kurz, Ruecklauf etwas laenger — das liest sich als Schlag statt
	# als Atmen. Bei schnellem Puls anteilig gestaucht.
	var up: float = minf(interval * 0.18, 0.10)
	var down: float = minf(interval * 0.42, 0.28)

	_marker.pivot_offset = _marker.size * 0.5
	_beat_tween = create_tween()
	_beat_tween.tween_property(_marker, "scale", Vector2.ONE * (1.0 + amp), up)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_beat_tween.tween_property(_marker, "scale", Vector2.ONE, down)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_beat_tween.tween_interval(maxf(interval - up - down, 0.0))
	_beat_tween.tween_callback(_beat_once)

func _play_heartbeat() -> void:
	if not heartbeat_audio_enabled or _heart_player.stream == null:
		return
	if value > heartbeat_below_health:
		return
	# Ab der Hoerschwelle sanft einblenden statt schlagartig einsetzen.
	var t: float = inverse_lerp(heartbeat_below_health, 0.0, value)
	_heart_player.volume_db = lerpf(heartbeat_min_db, heartbeat_max_db, clampf(t, 0.0, 1.0))
	# Neu ab 0 starten — loest einen noch klingenden Schlag ab statt ihn zu
	# ueberlagern, falls der Puls schneller ist als die Aufnahme lang.
	_heart_player.play(0.0)

# ---------------------------------------------------------------------------

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
	if GameState.phase == GameState.Phase.SETUP and fill_time > 0.0:
		_kill_fill_tween()
		_fill_tween = create_tween()
		_fill_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_fill_tween.tween_method(_set_bar_value, value, new_health, fill_time)
		return
	_kill_fill_tween()
	_set_bar_value(new_health)

func _kill_fill_tween() -> void:
	if _fill_tween and _fill_tween.is_valid():
		_fill_tween.kill()
	_fill_tween = null

func _set_bar_value(v: float) -> void:
	value = v
	_follow_fill()

## X-Position des Herzens an die Fuellkante koppeln (Y bleibt zentriert).
func _follow_fill() -> void:
	if not is_instance_valid(_marker):
		return
	var ratio: float = value / max_value if max_value > 0.0 else 0.0
	_marker.position.x = ratio * size.x - _marker.size.x * 0.5
