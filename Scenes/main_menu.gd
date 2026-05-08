extends Control
@onready var main: VBoxContainer = $main
@onready var credits: VBoxContainer = $credits


func _ready() -> void:
	main.visible = true
	credits.visible = false

func _on_start_bt_pressed() -> void:
	get_tree().change_scene_to_file("res://Main.tscn")


func _on_options_bt_pressed() -> void:
	pass
	
func _on_credit_bt_pressed() -> void:
	main.visible = !main.visible
	credits.visible = !credits.visible

func _on_exit_bt_pressed() -> void:
	get_tree().quit()
