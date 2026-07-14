extends Node

signal manual_acquired_changed(acquired: bool)
signal ship_lights_changed(value: bool)
signal door_unlocked(door_id: String)
signal door_locked(door_id: String)

# ===== JOURNEY (zeitlich begrenzte Reparatur-Phase) =====
signal phase_changed(phase: int)
signal health_changed(value: float)
signal time_changed(seconds_left: float)
signal malfunctions_solved_changed(count: int)
signal broken_systems_changed()
signal run_finished(results: Dictionary)
signal questionnaire_submitted(answers: Array)

enum Phase { SETUP, JOURNEY, RESULTS }

var doors: Dictionary = {
	"keypad1" = false,
	"main_door" = false,
	"storage_door" = false,
	"right_engin_door" = false,
	"left_engin_door" = false,
}

var ship_lights: bool = false:
	set(value):
		ship_lights = value
		ship_lights_changed.emit(value)
		
var manule_aquiered: bool = false:
	set(value):
		manule_aquiered = value
		manual_acquired_changed.emit(value)

func unlock_door(door_id: String) -> void:
	doors[door_id] = true
	door_locked.emit(door_id)
	# Während der Journey-Phase zählt das Lösen als erledigte Aufgabe
func lock_door(door_id: String) -> void:
	doors[door_id] = false
	door_locked.emit(door_id)

func is_door_unlocked(door_id: String) -> bool:
	return doors.get(door_id, false)

func remove_door(door_id: String) -> void:
	doors.erase(door_id)
	
func is_manual_aquiered() -> bool:
	return manule_aquiered

# =====================================================================
# JOURNEY-PHASE
# Zeitlich begrenztes Messfenster: Schiff verliert Leben, Störungen
# (Malfunctions) erscheinen über die Zeit nach einer Kurve, Spieler
# repariert sie. Score = Anzahl gelöster Störungen im Fenster.
# =====================================================================

# ---- Einstellbare Werte (alles an einem Ort) ----
@export_group("Journey")
@export var run_duration := 440.0             ## Messfenster in Sekunden
@export var max_health := 100.0                ## Maximales + Start-Leben
@export var health_per_fix := 20.0             ## Reparatur stellt so viel wieder her (flach)
@export var health_drain_per_sec := 0.4       ## passiver Verlust pro Sekunde
@export var drain_per_active_malfunction := 0.05## extra Verlust pro offener Störung (0 = aus)

# Hinweis: Jede Stoerung hat ihren eigenen spawn_time (Sekunden ab Journey-Start).

# ---- Versuchsvariablen (Settings) ----
var dyslexia_enabled := true                   ## Dyslexie-Effekt an/aus
var stress_from_health := true                 ## wenig Leben -> mehr Stress

# ---- Laufzeit-Zustand ----
var phase: int = Phase.SETUP
var health: float = 0.0
var time_left: float = 0.0
var malfunctions_solved: int = 0
var died_early := false
var _malfunctions: Array[Node] = []            ## alle Journey-Stoerungen, registrieren sich selbst
var _run_log: Array[Dictionary] = []

# ---- Lauf-Identitaet (Export selbst macht der ResultsExporter-Autoload) ----
## Teilnehmer-Kennung. Wird einmal pro App-Start generiert (Konvention: fuer
## jeden Teilnehmer wird das Spiel neu gestartet). Kann vor dem Lauf manuell
## ueberschrieben werden (z. B. spaeter ueber ein Eingabefeld).
var participant_id := ""
## Antwort aus dem Startup-Popup ("Wurde bei Ihnen eine Lese-Rechtschreib-Schwaeche
## festgestellt?"). Wird pro App-Start einmal gesetzt und mit jeder Run-Zeile
## exportiert, damit dyslexia_enabled=false eindeutig interpretierbar bleibt
## (Kontrollgruppe vs. betroffene Person). Absichtlich NICHT in reset_game().
var participant_has_dyslexia := false
var _run_index := 0                            ## Laufnummer innerhalb dieser Sitzung
var _run_id := ""                              ## eindeutig pro Lauf, verknuepft runs.csv & tasks.csv

# ---- Feste Kategorie-Zähler (Journey): hochzählen bei activate, runter bei win ----
var broken_strom: int = 0
var broken_treibstoff: int = 0
var broken_schild: int = 0
var broken_navigation: int = 0

## Journey-Stoerungen registrieren sich hier (statt beim alten Spawner).
func register_malfunction(m: Node) -> void:
	if m not in _malfunctions:
		_malfunctions.append(m)

## Malfunction wieder austragen, wenn sie die Szene verlaesst — sonst behaelt
## GameState tote Referenzen (Crash beim naechsten Durchlauf).
func unregister_malfunction(m: Node) -> void:
	_malfunctions.erase(m)

## Anzahl aktuell offener Journey-Stoerungen (fuer Drain).
func active_unsolved_count() -> int:
	var n := 0
	for m in _malfunctions:
		if m.has_method("is_active_unsolved") and m.is_active_unsolved():
			n += 1
	return n

## Von einer Malfunction aufgerufen, wenn sie aktiv wird (System fällt aus). Zähler +1.
func set_system_broken(system: String) -> void:
	match system:
		"strom": broken_strom += 1
		"treibstoff": broken_treibstoff += 1
		"schild": broken_schild += 1
		"navigation": broken_navigation += 1
		_: return
	broken_systems_changed.emit()

## Von einer Malfunction aufgerufen, wenn sie repariert wird. Zähler -1 (nie unter 0).
func set_system_repaired(system: String) -> void:
	match system:
		"strom": broken_strom = max(0, broken_strom - 1)
		"treibstoff": broken_treibstoff = max(0, broken_treibstoff - 1)
		"schild": broken_schild = max(0, broken_schild - 1)
		"navigation": broken_navigation = max(0, broken_navigation - 1)
		_: return
	broken_systems_changed.emit()

## True, wenn mindestens eine Störung dieser Kategorie aktiv ist.
func is_system_broken(system: String) -> bool:
	match system:
		"strom": return broken_strom > 0
		"treibstoff": return broken_treibstoff > 0
		"schild": return broken_schild > 0
		"navigation": return broken_navigation > 0
	return false

## True, wenn eine ANDERE Stoerung derselben Kategorie gerade aktiv (und ungeloest)
## ist. Prueft die Instanzen direkt statt der Zaehler, weil eine Asteroiden-Stoerung
## erst nach ihrem Anflug hochzaehlt, aber schon vorher als aktiv gilt.
func is_category_active(category_name: String, exclude: Node = null) -> bool:
	if category_name == "":
		return false
	for m in _malfunctions:
		if m == exclude or not is_instance_valid(m):
			continue
		if m.has_method("is_active_unsolved") and m.is_active_unsolved() \
				and m.has_method("get_category_name") and m.get_category_name() == category_name:
			return true
	return false

func is_any_system_broken() -> bool:
	if broken_strom > 0 or broken_treibstoff > 0 or broken_schild > 0 or broken_navigation > 0 :
		return true
	return false

func _ready() -> void:
	set_process(false)  # Journey-Loop läuft erst ab start_journey()
	if participant_id.is_empty():
		# "2026-06-10T14:33:02" -> "P20260610-143302"
		participant_id = "P" + Time.get_datetime_string_from_system().replace("-", "").replace(":", "").replace("T", "-")

## Setzt den GESAMTEN Spielzustand auf Anfang zurueck.
## Beim Start eines neuen Spiels ueber das Hauptmenue aufrufen — NICHT in
## start_journey() (das ist nur das zeitlich begrenzte Messfenster).
## Versuchs-Einstellungen (dyslexia_enabled, stress_from_health) bleiben absichtlich erhalten.
func reset_game() -> void:
	set_process(false)
	phase = Phase.SETUP

	# Kategorie-Zaehler
	broken_strom = 0
	broken_treibstoff = 0
	broken_schild = 0
	broken_navigation = 0

	# Tueren in den Ausgangszustand
	for key in doors:
		doors[key] = false

	# Schiffszustand (Setter feuern die jeweiligen Signale)
	manule_aquiered = false
	ship_lights = false

	# Journey-Laufzeitwerte
	health = 0.0
	time_left = 0.0
	malfunctions_solved = 0
	died_early = false
	_malfunctions.clear()
	_run_log.clear()

	# Dyslexie: kein Stress, Effekte je nach Einstellung
	DyslexiaManager.stress = 0.0
	DyslexiaManager.accessibility = not dyslexia_enabled

	broken_systems_changed.emit()

func start_journey() -> void:
	phase = Phase.JOURNEY
	health = max_health
	time_left = run_duration
	malfunctions_solved = 0
	died_early = false
	_run_log.clear()
	_run_index += 1
	_run_id = "%s-run%02d" % [participant_id, _run_index]
	# Zaehler/Tueren/Manual werden in reset_game() beim Spielstart geleert (ueber das
	# Hauptmenue), NICHT hier — start_journey() startet nur das Messfenster.
	_apply_stress_from_health()
	# Tote Eintraege entfernen (Stoerungen aus einem frueheren Durchlauf, die mit
	# der alten Szene freigegeben wurden) — sonst Crash auf "freed instance".
	for i in range(_malfunctions.size() - 1, -1, -1):
		if not is_instance_valid(_malfunctions[i]):
			_malfunctions.remove_at(i)
	# Alle Journey-Stoerungen zuruecksetzen (Tutorial-Stoerungen verwalten sich selbst).
	for m in _malfunctions:
		if m.has_method("reset_for_journey"):
			m.reset_for_journey()
	phase_changed.emit(phase)
	health_changed.emit(health)
	time_changed.emit(time_left)
	set_process(true)

func _process(delta: float) -> void:
	if phase != Phase.JOURNEY:
		return

	time_left = max(0.0, time_left - delta)
	time_changed.emit(time_left)

	# Leben: passiver Verlust + extra pro offener Störung
	var active_count := active_unsolved_count()
	var drain := health_drain_per_sec + drain_per_active_malfunction * active_count
	_set_health(health - drain * delta)

	# Stoerungen nach eigenem spawn_time aktivieren (kein Spawner mehr).
	var elapsed := run_duration - time_left
	for m in _malfunctions:
		if m.has_method("try_spawn"):
			m.try_spawn(elapsed)

	if health <= 0.0:
		died_early = true
		_finish_run()
	elif time_left <= 0.0:
		_finish_run()
	ship_lights = is_system_broken("strom")

func submit_questionnaire(answers: Array) -> void:
	questionnaire_submitted.emit(answers)

func get_current_run_id() -> String:
	return _run_id	

func _report_malfunction_solved(puzzle_id: String) -> void:
	if phase != Phase.JOURNEY:
		return
	malfunctions_solved += 1
	_set_health(health + health_per_fix)
	_run_log.append({
		"puzzle_id": puzzle_id,
		"time_left": time_left,
		"elapsed": run_duration - time_left,   # Sekunden seit Journey-Start
	})
	malfunctions_solved_changed.emit(malfunctions_solved)

func _set_health(value: float) -> void:
	health = clampf(value, 0.0, max_health)
	health_changed.emit(health)
	_apply_stress_from_health()

func _apply_stress_from_health() -> void:
	if stress_from_health and dyslexia_enabled:
		DyslexiaManager.stress = (1.0 - health / max_health) * 100.0
	DyslexiaManager.accessibility = not dyslexia_enabled

func _finish_run() -> void:
	set_process(false)
	phase = Phase.RESULTS
	for m in _malfunctions:
		if m.has_method("deactivate"):
			m.deactivate()
	phase_changed.emit(phase)
	var results := {
		"run_id": _run_id,
		"participant_id": participant_id,
		"timestamp": Time.get_datetime_string_from_system(),
		"malfunctions_solved": malfunctions_solved,
		"died_early": died_early,
		"run_duration": run_duration,
		"time_used": run_duration - time_left,
		"dyslexia_enabled": dyslexia_enabled,
		"stress_from_health": stress_from_health,
		"has_dyslexia": participant_has_dyslexia,
		"log": _run_log.duplicate(),
	}
	# ResultsExporter (Autoload) lauscht auf run_finished und schreibt die CSVs.
	run_finished.emit(results)
	# Zum Endscreen wechseln (liest Werte selbst aus GameState).
	SceneSwitcher.switch_scene("res://Scenes/Menu/EndSceen.tscn")
