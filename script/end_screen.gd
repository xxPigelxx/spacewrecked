extends CanvasLayer

## Endscreen. Kommt nach dem End-Fragebogen (post_flow), der den Durchlauf
## bereits abgeschickt hat. Liest die Run-Ergebnisse direkt aus GameState.

@onready var main: VBoxContainer = $main
@onready var credits: VBoxContainer = $credits
@onready var title_label: Label = $Label
@onready var results_label: RichTextLabel = $main/Results
@onready var tasks_label: Label = $main/Tasks
@onready var time_label: Label = $main/Time
@onready var completed_label: Label = $main/Compleated
@onready var quit_bt: Button = $main/HBoxContainer/QuitBt
@onready var pop_up: MarginContainer = $PopUp

func _ready() -> void:
	pop_up.visible = true
	main.visible = false
	credits.visible = false
	title_label.visible = true
	_fill_results()
	if OS.has_feature("web"):
		quit_bt.visible = false

func _fill_results() -> void:
	var solved: int = GameState.malfunctions_solved
	var died: bool = GameState.died_early
	var run_duration: float = GameState.run_duration

	# Ergebnis-Ueberschrift je nach Ausgang.
	if died:
		title_label.text = "Schiff zerstoert"
		results_label.text = "[center]Ergebnis: Schiff zerstoert"
	else:
		title_label.text = "Geschafft!"
		results_label.text = "[center]Ergebnis: Zeit ueberstanden"

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
	await ResultsExporter.await_pending_uploads()
	get_tree().quit()


func _on_close_pop_up_bt_pressed() -> void:
	pop_up.visible = false
	main.visible = true
