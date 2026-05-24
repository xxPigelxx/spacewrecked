extends Node
@onready var main: VBoxContainer = $main
@onready var credits: VBoxContainer = $credits
@onready var options: VBoxContainer = $Options
@onready var label: Label = $Label


func _ready() -> void:
	main.visible = true
	credits.visible = false
	options.visible = false
	_update_label()
	
func _update_label() ->void:
	var lable_text = "Menu"
	if options.visible:
		lable_text = "Options"
	elif credits.visible:
		lable_text = "Credits"
		
	label.text = lable_text


func _on_main_menu_bt_pressed() -> void:
	SceneSwitcher.close_overlay_and_switch_scene("res://Scenes/Menu/MainMenu.tscn")

func _on_options_bt_pressed() -> void:
	main.visible = !main.visible
	options.visible = !options.visible
	_update_label()
	
func _on_credit_bt_pressed() -> void:
	main.visible = !main.visible
	credits.visible = !credits.visible
	_update_label()

func _on_return_bt_pressed() -> void:
	SceneSwitcher.close_overlay_scene()
