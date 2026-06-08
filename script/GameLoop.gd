extends Node

## GameLoop — steuert die zeitlich begrenzte "Journey"-Phase.
##
## Phasen:
##   SETUP   = Tutorial, jedes Puzzle einmal lösen (bestehender Ablauf)
##   JOURNEY = 5-Minuten-Fenster, Schiff verliert passiv Leben,
##             feste Reihenfolge von Aufgaben taucht auf, Spieler repariert
##   RESULTS = Auswertung (Anzahl gelöster Aufgaben) + Daten-Export
##
## Die Aufgaben-Reihenfolge ist für ALLE Spieler identisch — nötig für
## den Vergleich in der BA.

signal phase_changed(phase: int)
signal health_changed(value: float)
signal time_changed(seconds_left: float)
signal task_started(index: int, task: Dictionary)
signal task_completed(index: int, task: Dictionary, time_taken: float)
signal tasks_completed_changed(count: int)
signal run_finished(results: Dictionary)

enum Phase { SETUP, JOURNEY, RESULTS }

# ---- Einstellbare Werte (Platzhalter — frei anpassbar) ----
@export var run_duration := 300.0        ## Messfenster in Sekunden (5 Min)
@export var max_health := 100.0
@export var health_drain_per_sec := 1.0  ## passiver Verlust pro Sekunde
@export var health_per_fix := 20.0       ## Reparatur stellt so viel wieder her
@export var seconds_between_tasks := 4.0  ## Pause, bis die nächste Aufgabe erscheint

# ---- Einstellungen (Versuchsvariablen) ----
## Dyslexie-Effekt an/aus (entspricht NICHT-accessibility).
var dyslexia_enabled := true
## Wenn true: Schiffsgesundheit steuert den Stress-Level (wenig Leben = viel Stress).
var stress_from_health := true

# ---- Feste Aufgaben-Reihenfolge (für alle gleich) ----
## Jeder Eintrag: { "scene": res-path, "puzzle_id": String, "marker_id": String, "data": Dictionary }
## marker_id = welches Interactable in der Welt aufleuchtet.
## Varianten später als eigene Szenen-Pfade eintragen.
var task_sequence: Array[Dictionary] = [
	{ "scene": "res://Scenes/Puzzle/CableGame.tscn", "puzzle_id": "cable1", "marker_id": "cable", "data": {} },
	{ "scene": "res://Scenes/Puzzle/CableGame.tscn", "puzzle_id": "cable1", "marker_id": "cable", "data": {} },
	{ "scene": "res://Scenes/Puzzle/CableGame.tscn", "puzzle_id": "cable1", "marker_id": "cable", "data": {} },
	{ "scene": "res://Scenes/Puzzle/CableGame.tscn", "puzzle_id": "cable1", "marker_id": "cable", "data": {} },
	{ "scene": "res://Scenes/Puzzle/CableGame.tscn", "puzzle_id": "cable1", "marker_id": "cable", "data": {} },
]

# ---- Laufzeit-Zustand ----
var phase: int = Phase.SETUP
var health: float = 0.0
var time_left: float = 0.0
var task_index: int = -1            ## Index der aktuell laufenden Aufgabe (-1 = keine)
var tasks_completed: int = 0
var died_early := false

var _task_start_time := 0.0
var _next_task_at := 0.0            ## time_left-Wert, bei dem die nächste Aufgabe startet
var _task_active := false
var _run_log: Array[Dictionary] = []  ## pro Aufgabe ein Eintrag (für CSV)

func _ready() -> void:
	set_process(false)

# ----------------------------
# JOURNEY START / LOOP
# ----------------------------

func start_journey() -> void:
	phase = Phase.JOURNEY
	health = max_health
	time_left = run_duration
	task_index = -1
	tasks_completed = 0
	died_early = false
	_task_active = false
	_run_log.clear()
	_next_task_at = run_duration - seconds_between_tasks
	_apply_stress_from_health()
	phase_changed.emit(phase)
	health_changed.emit(health)
	time_changed.emit(time_left)
	set_process(true)

func _process(delta: float) -> void:
	if phase != Phase.JOURNEY:
		return

	# Zeit herunterzählen
	time_left = max(0.0, time_left - delta)
	time_changed.emit(time_left)

	# Passiver Lebensverlust (läuft die ganze Journey über — offene Aufgaben erhöhen den Druck)
	_set_health(health - health_drain_per_sec * delta)

	# Nächste Aufgabe starten?
	if not _task_active and time_left <= _next_task_at and task_index + 1 < task_sequence.size():
		_start_next_task()

	# Ende-Bedingungen
	if health <= 0.0:
		died_early = true
		_finish_run()
	elif time_left <= 0.0:
		_finish_run()

# ----------------------------
# TASKS
# ----------------------------

func _start_next_task() -> void:
	task_index += 1
	var task: Dictionary = task_sequence[task_index]
	_task_active = true
	_task_start_time = time_left
	# Kein Overlay erzwingen — stattdessen Signal: die Welt zeigt das Interactable.
	task_started.emit(task_index, task)

## Von der Puzzle-Logik aufgerufen (über GameState.solve_puzzle -> hier),
## wenn die aktuell offene Aufgabe gelöst wurde.
func report_task_solved(puzzle_id: String) -> void:
	if phase != Phase.JOURNEY or not _task_active:
		return
	var task: Dictionary = task_sequence[task_index]
	if task.get("puzzle_id", "") != puzzle_id:
		return  # nicht die aktuelle Aufgabe
	var time_taken := _task_start_time - time_left
	_task_active = false
	tasks_completed += 1
	_set_health(health + health_per_fix)
	_next_task_at = time_left - seconds_between_tasks

	_run_log.append({
		"index": task_index,
		"puzzle_id": puzzle_id,
		"scene": task.get("scene", ""),
		"time_taken": time_taken,
	})
	task_completed.emit(task_index, task, time_taken)
	tasks_completed_changed.emit(tasks_completed)

# ----------------------------
# HEALTH / STRESS
# ----------------------------

func _set_health(value: float) -> void:
	health = clampf(value, 0.0, max_health)
	health_changed.emit(health)
	_apply_stress_from_health()

func _apply_stress_from_health() -> void:
	if stress_from_health and dyslexia_enabled:
		# wenig Leben -> viel Stress
		DyslexiaManager.stress = (1.0 - health / max_health) * 100.0
	DyslexiaManager.accessibility = not dyslexia_enabled

# ----------------------------
# RESULTS
# ----------------------------

func _finish_run() -> void:
	set_process(false)
	phase = Phase.RESULTS
	phase_changed.emit(phase)
	var results := {
		"tasks_completed": tasks_completed,
		"died_early": died_early,
		"run_duration": run_duration,
		"time_left": time_left,
		"dyslexia_enabled": dyslexia_enabled,
		"stress_from_health": stress_from_health,
		"log": _run_log,
	}
	run_finished.emit(results)
	deliver_results(results)

## Flexible Daten-Lieferung — später eine Methode wählen:
## CSV-Download im Browser, Code zum Abtippen, oder POST an Google Sheet.
## Vorerst: CSV-String bauen und in die Konsole + user://-Datei schreiben.
func deliver_results(results: Dictionary) -> void:
	var csv := build_csv(results)
	print("=== RUN RESULTS (CSV) ===")
	print(csv)
	# Lokale Datei (Desktop: sichtbar; Web: in IndexedDB, nicht direkt zugänglich)
	var f := FileAccess.open("user://results.csv", FileAccess.WRITE)
	if f:
		f.store_string(csv)
		f.close()

## Baut eine CSV-Zeile (mit Header) aus den Ergebnissen.
func build_csv(results: Dictionary) -> String:
	var header := "tasks_completed,died_early,run_duration,dyslexia_enabled,stress_from_health"
	var row := "%d,%s,%.0f,%s,%s" % [
		results.get("tasks_completed", 0),
		str(results.get("died_early", false)),
		results.get("run_duration", 0.0),
		str(results.get("dyslexia_enabled", false)),
		str(results.get("stress_from_health", false)),
	]
	return header + "\n" + row
