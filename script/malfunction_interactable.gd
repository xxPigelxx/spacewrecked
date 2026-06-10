extends Interactable
class_name MalfunctionInteractable

## Eine Stoerung in der Journey- oder Tutorial-Phase.
## Versteckt, bis der Spawner activate() aufruft; oeffnet dann bei Interaktion
## das zugehoerige Puzzle (overlay_scene/overlay_data aus dem Inspector).
## Schiffssystem-Kategorie dieser Stoerung (festes Dropdown). Muss gesetzt werden.
enum Category { NICHT_GESETZT, STROM, TREIBSTOFF, SCHILD, NAVIGATION }
@export var category: Category = Category.NICHT_GESETZT
## TUTORIAL: taucht sofort auf, verwaltet sich selbst (kein Score/Health-Report).
## JOURNEY: taucht nach spawn_time Sekunden ab Journey-Start auf, wird gezaehlt.
enum Phase { TUTORIAL, JOURNEY }
@export var phase: Phase = Phase.JOURNEY
@export var spawn_time: float = 0.0     ## Sekunden ab Journey-Start (nur JOURNEY)
@export var start_up_animation: AnimatedSprite2D = null
@export var partical: CPUParticles2D = null
var _active := false
var _solved := false
var _counted := false        ## ob diese Stoerung aktuell im Kategorie-Zaehler steckt
var _spawned := false        ## ob try_spawn sie in dieser Journey schon aktiviert hat


func _setup() -> void:
	_active = false
	visible = false
	if label:
		label.visible = false
	if phase == Phase.TUTORIAL:
		activate()              # Tutorial: sofort sichtbar, self-managed
	else:
		GameState.register_malfunction(self)  # Journey: wartet auf spawn_time

## Beim Verlassen der Szene austragen, damit GameState keine toten Referenzen behaelt.
func _exit_tree() -> void:
	if is_instance_valid(GameState):
		GameState.unregister_malfunction(self)

## Vom GameState pro Frame aufgerufen. Aktiviert sich, sobald elapsed >= spawn_time.
func try_spawn(elapsed: float) -> void:
	if _spawned or _active or _solved:
		return
	if elapsed >= spawn_time:
		_spawned = true
		activate()

## Vor Journey-Start zuruecksetzen, damit erneute Laeufe sauber starten.
func reset_for_journey() -> void:
	_spawned = false
	_solved = false
	deactivate()
	

## Kategorie als String fuer GameState (muss zu HomePanel passen).
func _category_name() -> String:
	match category:
		Category.STROM: return "strom"
		Category.TREIBSTOFF: return "treibstoff"
		Category.SCHILD: return "schild"
		Category.NAVIGATION: return "navigation"
	return ""

## Stoerung sichtbar + interagierbar machen. System faellt aus (Zaehler +1).
func activate() -> void:
	if _active:
		return
	_active = true
	_solved = false
	visible = true
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	if not _counted:
		_counted = true
		var cat := _category_name()
		if cat == "":
			push_warning("MalfunctionInteractable '%s': category ist NICHT_GESETZT — System wird nicht ins Buch gezählt." % name)
		GameState.set_system_broken(cat)
	if start_up_animation:
		start_up_animation.play()
	if partical:
		partical.emitting = true
## Stoerung ausblenden + deaktivieren.
## Falls die Stoerung noch gezaehlt war (aber nicht geloest), Zaehler bereinigen,
## damit _counted konsistent bleibt (z.B. bei Reset/begin oder clear_all).
func deactivate() -> void:
	_active = false
	visible = false
	player_near = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	if label:
		label.visible = false
	if _counted and not _solved:
		_counted = false
		GameState.set_system_repaired(_category_name())
	if partical:
		partical.emitting = false
## Wird vom Spawner fuer die Lebens-/Kurven-Logik abgefragt.
func is_active_unsolved() -> bool:
	return _active and not _solved

## Vom Spawner aufgerufen, wenn dieses Puzzle geloest wurde. System wieder aktiv (Zaehler -1).
func mark_solved() -> void:
	_solved = true
	deactivate()
	if _counted:
		_counted = false
		GameState.set_system_repaired(_category_name())
	# Journey-Score/Health/Log nur für Journey-Störungen, nicht für Tutorial.
	if phase == Phase.JOURNEY:
		GameState._report_malfunction_solved(_category_name())

## Nur reagieren, wenn aktiv. Meldet sich als "in Bearbeitung" beim Spawner.
func _action() -> void:
	if not _active or _solved:
		return
	if overlay_scene != "":
		SceneSwitcher.open_overlay_with_data(overlay_scene, {"malfunction": self}, true, false)
