extends Control
@onready var main: VBoxContainer = $main
@onready var credits: VBoxContainer = $credits
@onready var options: VBoxContainer = $Options
@onready var start_up_pop_up: MarginContainer = $StartUpPopUp


func _ready() -> void:
	start_up_pop_up.visible = true
	main.visible = false
	credits.visible = false
	options.visible = false
	AudioManager.play_music("res://resources/assets/sfx/Sci-Fi Music Pack/Loops/wav/Sci-Fi 5 Loop.wav")

func _on_start_bt_pressed() -> void:
	GameState.reset_game()
	SceneSwitcher.switch_scene("res://Scenes/MainGame.tscn")

func _on_options_bt_pressed() -> void:
	main.visible = !main.visible
	options.visible = !options.visible

func _on_credit_bt_pressed() -> void:
	main.visible = !main.visible
	credits.visible = !credits.visible

func _on_exit_bt_pressed() -> void:
	get_tree().quit()


func _on_close_pop_up_bt_pressed() -> void:
	start_up_pop_up.visible = false
	main.visible = true
