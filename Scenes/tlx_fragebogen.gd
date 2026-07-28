extends PanelContainer

@onready var submit_button: Button = $MarginContainer/ScrollContainer/VBoxContainer/SubmitButton
@onready var question_container: VBoxContainer = $MarginContainer/ScrollContainer/QuestionContianer

## "pre" oder "post" — in der Post-Szene im Inspector umstellen.
@export var block: String = "pre"


func _process(_delta: float) -> void:
	submit_button.disabled = not _all_answered()


func _all_answered() -> bool:
	for question in question_container.get_children():
		if question is Question and not question.is_answered():
			return false
	return true


func _get_answers() -> Array:
	var results: Array = []
	for question in question_container.get_children():
		if question is Question:
			results.append({
				"name": question.name,
				"selected": question.get_selected(),
			})
	return results


func _on_submit_button_pressed() -> void:
	ResultsExporter.store_answers(block, _get_answers())
