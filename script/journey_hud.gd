extends CanvasLayer

## Temporäres Debug-HUD für die Journey-Phase.
## Zeigt Schiffsgesundheit, verbleibende Zeit und gelöste Aufgaben.
## Self-contained: baut seine Labels selbst, einfach in die Szene legen.

var _health_bar: ProgressBar
var _time_label: Label
var _tasks_label: Label
var _root: VBoxContainer

func _ready() -> void:
	layer = 100  # über allem
	_build_ui()
	GameLoop.health_changed.connect(_on_health)
	GameLoop.time_changed.connect(_on_time)
	GameLoop.tasks_completed_changed.connect(_on_tasks)
	GameLoop.phase_changed.connect(_on_phase)
	GameLoop.run_finished.connect(_on_run_finished)
	visible = false  # erst in der Journey zeigen

func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(20, 20)
	add_child(panel)

	_root = VBoxContainer.new()
	_root.custom_minimum_size = Vector2(260, 0)
	panel.add_child(_root)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.remove_child(_root)
	margin.add_child(_root)
	panel.add_child(margin)

	var hp_title := Label.new()
	hp_title.text = "Schiff"
	_root.add_child(hp_title)

	_health_bar = ProgressBar.new()
	_health_bar.min_value = 0.0
	_health_bar.max_value = 100.0
	_health_bar.value = 100.0
	_health_bar.custom_minimum_size = Vector2(0, 22)
	_root.add_child(_health_bar)

	_time_label = Label.new()
	_time_label.text = "Zeit: --:--"
	_root.add_child(_time_label)

	_tasks_label = Label.new()
	_tasks_label.text = "Aufgaben: 0"
	_root.add_child(_tasks_label)

func _on_health(value: float) -> void:
	if _health_bar:
		_health_bar.max_value = GameLoop.max_health
		_health_bar.value = value

func _on_time(seconds_left: float) -> void:
	if _time_label:
		var m := int(seconds_left) / 60
		var s := int(seconds_left) % 60
		_time_label.text = "Zeit: %d:%02d" % [m, s]

func _on_tasks(count: int) -> void:
	if _tasks_label:
		_tasks_label.text = "Aufgaben: %d" % count

func _on_phase(phase: int) -> void:
	visible = (phase == GameLoop.Phase.JOURNEY)

func _on_run_finished(results: Dictionary) -> void:
	# Kurzes Ergebnis im HUD anzeigen
	visible = true
	if _tasks_label:
		var ended := "GAME OVER" if results.get("died_early", false) else "ZEIT UM"
		_tasks_label.text = "%s — Aufgaben: %d" % [ended, results.get("tasks_completed", 0)]
	if _time_label:
		_time_label.text = "Lauf beendet"
