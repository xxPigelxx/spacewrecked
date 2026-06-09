extends CanvasLayer

## Endscreen. Wird nach _finish_run() vom GameState angesteuert
## (SceneSwitcher.switch_scene). Liest die Run-Ergebnisse direkt aus GameState.

@onready var main: VBoxContainer = $main
@onready var credits: VBoxContainer = $credits
@onready var title_label: Label = $Label
@onready var results_label: RichTextLabel = $main/Results
@onready var tasks_label: Label = $main/Tasks
@onready var time_label: Label = $main/Time
@onready var completed_label: Label = $main/Compleated

func _ready() -> void:
	main.visible = true
	credits.visible = false
	_fill_results()

func _fill_results() -> void:
	var solved: int = GameState.malfunctions_solved
	var died: bool = GameState.died_early
	var run_duration: float = GameState.run_duration

	# Ergebnis-Ueberschrift je nach Ausgang.
	if died:
		title_label.text = "Schiff zerstoert"
		results_label.text = "[u]Ergebnis: Schiff zerstoert"
	else:
		title_label.text = "Geschafft!"
		results_label.text = "[u]Ergebnis: Zeit ueberstanden"

	# Genutzte Zeit: bei died_early < run_duration, sonst volle Dauer.
	var time_used: float = run_duration - max(0.0, GameState.time_left)
	tasks_label.text = "Reparaturen: %d" % solved
	time_label.text = "Zeit: %d s / %d s" % [int(round(time_used)), int(round(run_duration))]
	completed_label.text = "Dyslexie-Modus: %s" % ("an" if GameState.dyslexia_enabled else "aus")

func _on_credit_bt_pressed() -> void:
	main.visible = !main.visible
	credits.visible = !credits.visible

func _on_main_menu_bt_pressed() -> void:
	SceneSwitcher.switch_scene("res://Scenes/Menu/MainMenu.tscn")

func _on_return_bt_pressed() -> void:
	get_tree().quit()
