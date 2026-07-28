extends Control
@onready var main: VBoxContainer = $main
@onready var credits: VBoxContainer = $credits
@onready var options: VBoxContainer = $Options
@onready var start_up_pop_up: MarginContainer = $StartUpPopUp
@onready var close_pop_up_bt: Button = $StartUpPopUp/PanelContainer/MarginContainer/VBoxContainer/ClosePopUpBt


func _ready() -> void:
	start_up_pop_up.visible = true
	main.visible = false
	credits.visible = false
	options.visible = false
	AudioManager.play_music("res://resources/assets/sfx/music/Sci-Fi 5 Loop.mp3")

func _on_start_bt_pressed() -> void:
	GameState.reset_game()
	# Erst der Vor-dem-Spiel-Block (Intro, TLX, Fragebogen); der wechselt am
	# Ende selbst ins MainGame.
	SceneSwitcher.switch_scene("res://Scenes/Menu/pre_flow.tscn")

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


## Pflichtfrage im Startup-Popup: erst nach Ja/Nein laesst sich das Popup schliessen.
## "Ja" (Dyslexie vorhanden) schaltet die Simulation ab; die Antwort selbst wird
## in GameState gespeichert und landet als eigene Spalte in der Run-Zeile im Sheet.
func _on_ja_bt_pressed() -> void:
	GameState.participant_has_dyslexia = true
	GameState.dyslexia_enabled = false
	close_pop_up_bt.disabled = false

func _on_nein_bt_pressed() -> void:
	GameState.participant_has_dyslexia = false
	GameState.dyslexia_enabled = true
	close_pop_up_bt.disabled = false
