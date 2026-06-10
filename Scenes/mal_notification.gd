extends TextureRect


func _ready() -> void:
	if GameState.has_signal("malfunctions_solved_changed"):
		GameState.malfunctions_solved_changed.connect(func(_c): refresh())
	if GameState.has_signal("broken_systems_changed"):
		GameState.broken_systems_changed.connect(func(): refresh())
	GameState.manual_acquired_changed.connect(func(_a): refresh())
	refresh()

func refresh():
	if GameState.is_any_system_broken() and GameState.is_manual_aquiered():
		visible = true
		AudioManager.play_sfx("res://resources/assets/sfx/Interface_Bleeps_Wav/Bleep_02.wav")
		return
	visible = false
