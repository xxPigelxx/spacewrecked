extends Node





func _on_button_pressed() -> void:
	SceneSwitcher.close_overlay_scene()


func _on_button_2_pressed() -> void:
	# Start-Schiff Button: Journey-Phase + Messfenster starten.
	GameState.start_journey()
	SceneSwitcher.close_overlay_scene()
