extends Control



func _on_start_bt_pressed() -> void:
	get_tree().change_scene_to_file("res://Main.tscn")


func _on_options_bt_pressed() -> void:
	pass # Replace with function body.


func _on_credit_bt_pressed() -> void:
	pass # Replace with function body.


func _on_exit_bt_pressed() -> void:
	get_tree().quit()
