extends Node





func _on_button_pressed() -> void:
	SceneSwitcher.close_overlay_scene()


func _on_button_2_pressed() -> void:
	# Start-Schiff Button. Hier eintragen, was beim Schiffsstart passieren soll.
	print("Schiff gestartet!")
	# z.B.: SceneSwitcher.close_overlay_scene()
	# z.B.: GameState.ship_lights = true
