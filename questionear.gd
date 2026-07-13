extends Control
@onready var v_box_container: VBoxContainer = $PanelContainer/MarginContainer/ScrollContainer/VBoxContainer
@onready var submit_button: Button = $SubmitButton  # Pfad anpassen

func _physics_process(delta: float) -> void:
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
	GameState.submit_questionnaire(get_results())
	self.visible = false
