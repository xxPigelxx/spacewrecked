extends TextureRect


func _ready() -> void:
	GameState.malfunctions_solved_changed.connect(func(_c): refresh())
	GameState.broken_systems_changed.connect(func(): refresh())
	GameState.manual_acquired_changed.connect(func(_a): refresh())
	refresh()

func refresh():
	var was_vis = visible
	if GameState.is_any_system_broken() and GameState.is_manual_aquiered():
		visible = true
		if not was_vis: AudioManager.play_sfx("res://resources/assets/sfx/Interface_Bleeps_Wav/Bleep_02.wav")
		return
	visible = false
