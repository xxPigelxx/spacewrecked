extends Question

## Optionale, pro Instanz gesetzte Antwortmoeglichkeiten. Ist das Array leer,
## bleiben die im Szenen-File definierten Popup-Eintraege erhalten (Rueckwaerts-
## kompatibel zum End-Fragebogen). Ist es gefuellt, ersetzen sie die Eintraege —
## so kann dieselbe Multiple-Choice-Szene z. B. fuer Ja/Nein wiederverwendet werden.
@export var options: PackedStringArray = []

@onready var option_button: OptionButton = $OptionButton

func _set_up() -> void:
	if options.size() > 0:
		option_button.clear()
		for opt in options:
			option_button.add_item(opt)
		# add_item waehlt sonst automatisch den ersten Eintrag aus -> Frage waere
		# faelschlich "beantwortet". Ohne Auswahl starten, Wahl erzwingen.
		option_button.selected = -1

func get_selected():
	var idx := option_button.selected
	return option_button.get_item_text(idx) if idx >= 0 else ""

func is_answered() -> bool:
	return option_button.selected != -1
