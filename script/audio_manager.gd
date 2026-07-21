extends Node

@onready var music_player: AudioStreamPlayer = $MusicAudioPlayer

const MAX_SFX := 8

var sfx_players: Array[AudioStreamPlayer] = []

var curently_playing_song: String = ""
var is_music_playing: bool = false

# optional: cache loaded sounds to avoid repeated disk loads
var sfx_cache := {}


func _ready():
	# create SFX pool
	for i in MAX_SFX:
		var player := AudioStreamPlayer.new()
		player.bus = "sfx"
		add_child(player)
		sfx_players.append(player)


# --------------------
# SFX SYSTEM (POOL)
# --------------------

func get_free_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	
	# fallback if all are busy (overwrites oldest slot)
	return sfx_players[0]

func play_sfx(path: String, volume_db: float = 0.0) -> void:
	var player := get_free_sfx_player()

	if not sfx_cache.has(path):
		sfx_cache[path] = load(path)

	player.stream = sfx_cache[path]
	player.volume_db = volume_db
	player.play()


func play_success():
	play_sfx("res://resources/assets/sfx/Interface_Bleeps_Wav/Confirm_01.wav")


# --------------------
# HERZSCHLAG
# --------------------
# Die Taktquelle liegt hier und nicht in der Health-Bar: SceneSwitcher friert
# beim Oeffnen eines Raetsel-Overlays den ganzen hud-Knoten ein (process_mode =
# DISABLED). Ein Puls in der Leiste wuerde also genau waehrend der Raetsel
# stehenbleiben. Der AudioManager ist Autoload und laeuft immer weiter.
# ship_health_bar.gd liest `heart_beat` fuer die Icon-Animation — so haben
# Bild und Ton denselben Takt.

const HEARTBEAT_SFX := "res://resources/assets/sfx/heartbeat.wav"

## Schlaege pro Sekunde bei vollem bzw. fast leerem Leben.
@export var heart_idle_bps := 1.0
@export var heart_max_bps := 3.0
## Ab welchem Schaden (0 = unverletzt, 1 = fast tot) wird der Schlag hoerbar?
@export_range(0.0, 1.0, 0.05) var heart_audible_from := 0.6
## Lautstaerke an der Hoerschwelle bzw. bei fast leerem Leben.
@export var heart_min_db := -18.0
@export var heart_max_db := -4.0
## Ton komplett abschaltbar — die Puls-Phase laeuft trotzdem weiter, damit das
## Herz-Icon unabhaengig davon animiert bleibt.
@export var heartbeat_audio_enabled := true

## 0..1 Puls fuer visuelle Kopplung (1 = Schlag), und aktueller Schaden 0..1.
var heart_beat: float = 0.0
var heart_intensity: float = 0.0

var _heart_phase: float = 0.0
var _heart_last_index: int = -1

func _process(delta: float) -> void:
	if not _heart_should_run():
		heart_beat = 0.0
		heart_intensity = 0.0
		_heart_phase = 0.0
		_heart_last_index = -1
		return

	heart_intensity = clampf(1.0 - GameState.health / GameState.max_health, 0.0, 1.0)
	var rate: float = lerpf(heart_idle_bps, heart_max_bps, heart_intensity)
	_heart_phase += delta * rate * TAU
	heart_beat = sin(_heart_phase) * 0.5 + 0.5

	# Ton genau im Puls-Maximum (sin-Scheitel bei PI/2) ausloesen, damit er
	# mit dem groessten Ausschlag des Icons zusammenfaellt.
	var index := floori((_heart_phase - PI * 0.5) / TAU)
	if index > _heart_last_index:
		_heart_last_index = index
		_play_heartbeat()

func _heart_should_run() -> bool:
	if not ("phase" in GameState) or GameState.phase != GameState.Phase.JOURNEY:
		return false
	return GameState.max_health > 0.0

func _play_heartbeat() -> void:
	if not heartbeat_audio_enabled:
		return
	if heart_intensity < heart_audible_from:
		return
	if not ResourceLoader.exists(HEARTBEAT_SFX):
		return
	# Ab der Hoerschwelle sanft einblenden statt schlagartig einsetzen.
	var t: float = inverse_lerp(heart_audible_from, 1.0, heart_intensity)
	play_sfx(HEARTBEAT_SFX, lerpf(heart_min_db, heart_max_db, clampf(t, 0.0, 1.0)))

# --------------------
# MUSIC SYSTEM
# --------------------

func play_music(path: String) -> void:
	if curently_playing_song == path:
		return

	if not sfx_cache.has(path):
		sfx_cache[path] = load(path)

	music_player.stream = sfx_cache[path]
	# Musik soll immer loopen — unabhaengig von der Import-Einstellung der Datei.
	if "loop" in music_player.stream:
		music_player.stream.loop = true
	curently_playing_song = path
	is_music_playing = true
	music_player.play()

	print("Music playing")


func stop_music() -> void:
	music_player.stop()
	is_music_playing = false


func replay_music() -> void:
	if curently_playing_song == "":
		return

	music_player.stream = sfx_cache[curently_playing_song]
	is_music_playing = true
	music_player.play()

	print("Music replayed")
