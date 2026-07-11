extends Control
@onready var v_box_container: VBoxContainer = $PanelContainer/MarginContainer/ScrollContainer/VBoxContainer

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
