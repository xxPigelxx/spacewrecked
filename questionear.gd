extends Control
@onready var v_box_container: VBoxContainer = $PanelContainer/MarginContainer/ScrollContainer/VBoxContainer
@onready var submit_button: Button = $SubmitButton  # Pfad anpassen
@onready var label: Label = $"../Label"

## Waehrend ein Upload laeuft, bleibt der Button gesperrt und das Panel offen —
## geschlossen wird erst, wenn ResultsExporter den Empfang bestaetigt hat.
var _sending := false

func _physics_process(_delta: float) -> void:
	if _sending:
		return
	submit_button.disabled = not are_all_answered()

func get_results() -> Array:
	var results: Array = []
	for c in v_box_container.get_children():
		if c is Question:
			results.append({"name": c.name, "selected": c.get_selected()})
	return results

func are_all_answered() -> bool:
	for c in v_box_container.get_children():
		if c is Question and not c.is_answered():
			return false
	return true

func _on_submit_button_pressed() -> void:
	if _sending:
		return
	_sending = true
	submit_button.disabled = true
	submit_button.text = "Senden..."
	GameState.submit_questionnaire(get_results())

	# Warten, bis GENAU der Fragebogen-Upload beantwortet ist (andere Uploads
	# wie run/task koennen parallel laufen und werden hier uebersprungen).
	while true:
		var args: Array = await ResultsExporter.upload_finished
		if args[0] != "questionnaire":
			continue
		if args[1]:
			self.visible = false
		else:
			submit_button.text = "Nochmal senden"
			submit_button.disabled = false
		_sending = false
		label.visible = true
		return
