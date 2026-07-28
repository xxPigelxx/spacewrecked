extends Control

@onready var v_box_container: VBoxContainer = $PanelContainer/MarginContainer/ScrollContainer/VBoxContainer
@onready var submit_button: Button = $SubmitButton
@onready var label: Label = $"../Label"

## "pre" oder "post" — in der jeweiligen Szene im Inspector setzen.
@export var block: String = "pre"

## Wird gefeuert, wenn der Fragebogen durch ist. Der Pre-Block nutzt das,
## um weiterzuschalten; beim Post-Block ist das Spiel danach zu Ende.
signal finished

## Nur relevant im Post-Block: waehrend des Uploads bleibt der Button gesperrt.
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

	ResultsExporter.store_answers(block, get_results())

	# Pre-Block: nur sammeln, nichts senden — es geht direkt weiter.
	if block == "pre":
		submit_button.disabled = true
		self.visible = false
		finished.emit()
		return

	# Post-Block: jetzt geht der gesamte Durchlauf in einem POST raus.
	_sending = true
	submit_button.disabled = true
	submit_button.text = "Senden..."

	var ok: bool = await ResultsExporter.submit()

	if ok:
		self.visible = false
		label.visible = true
		finished.emit()
	else:
		submit_button.text = "Nochmal senden"
		submit_button.disabled = false
		_sending = false
