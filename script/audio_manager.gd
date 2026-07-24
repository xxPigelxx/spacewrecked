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


func stop_music() -> void:
	music_player.stop()
	is_music_playing = false


func replay_music() -> void:
	if curently_playing_song == "":
		return

	music_player.stream = sfx_cache[curently_playing_song]
	is_music_playing = true
	music_player.play()
