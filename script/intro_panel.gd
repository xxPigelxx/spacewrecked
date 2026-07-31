extends PanelContainer
## Reine Textseite im Fragebogen-Ablauf — die intakte Handbuchseite, auf der
## die TLX-Baseline erhoben wird. Sammelt nichts, es gibt nichts zu beantworten.


func is_complete() -> bool:
	return true


func collect(_block: String) -> void:
	pass
