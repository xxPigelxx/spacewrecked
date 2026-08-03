extends PanelContainer

## Steuerungs-Hinweis zu Spielbeginn. Der Weiter-Knopf raeumt ihn weg; er kommt
## in diesem Durchlauf nicht wieder, weil die Szene pro Lauf neu geladen wird.

func _on_close_pop_up_bt_pressed() -> void:
	queue_free()
