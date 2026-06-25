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


func play_sfx(path: String) -> void:
	var player := get_free_sfx_player()

	if not sfx_cache.has(path):
		sfx_cache[path] = load(path)

	player.stream = sfx_cache[path]
	player.play()


# --------------------
# MUSIC SYSTEM
# --------------------

func play_music(path: String) -> void:
	if curently_playing_song == path:
		return

	if not sfx_cache.has(path):
		sfx_cache[path] = load(path)

	music_player.stream = sfx_cache[path]
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
