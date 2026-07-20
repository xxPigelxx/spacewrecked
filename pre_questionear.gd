extends Control

## Vor-dem-Spiel-Fragebogen. Wird nach "Start" im Hauptmenue angezeigt (vor
## MainGame). Die Antworten werden NICHT sofort gesendet, sondern in GameState
## zwischengelegt und am Ende zusammen mit dem End-Fragebogen hochgeladen
## (siehe GameState.submit_questionnaire) — deshalb hier kein Upload/Retry.

@onready var v_box_container: VBoxContainer = $PanelContainer/MarginContainer/ScrollContainer/VBoxContainer
@onready var submit_button: Button = $SubmitButton

func _physics_process(_delta: float) -> void:
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
	GameState.pre_questionnaire_answers = get_results()
	SceneSwitcher.switch_scene("res://Scenes/MainGame.tscn")
