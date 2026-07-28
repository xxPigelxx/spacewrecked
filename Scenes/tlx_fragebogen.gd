extends PanelContainer
## NASA-TLX-Schritt. Gleiche Aufgabe wie questionear.gd — eigene Datei, weil
## die Wurzel hier ein PanelContainer ist.


## Alle Question-Nodes darunter, egal wie tief verschachtelt. In eine Question
## selbst wird nicht abgestiegen — deren Kinder sind ihre Bedienelemente.
func _questions(node: Node = self, into: Array = []) -> Array:
	for child in node.get_children():
		if child is Question:
			into.append(child)
		else:
			_questions(child, into)
	return into


## Darf der Ablauf weiterschalten?
func is_complete() -> bool:
	for question in _questions():
		if not question.is_answered():
			return false
	return true


func collect(block: String) -> void:
	var answers: Array = []
	for question in _questions():
		answers.append({"name": question.name, "selected": question.get_selected()})
	ResultsExporter.store_answers(block, answers)
