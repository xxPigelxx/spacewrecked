extends Interactable
class_name MalfunctionInteractable

## Eine Stoerung in der Journey-Phase. Kind eines MalfunctionSpawner.
## Versteckt, bis der Spawner activate() aufruft; oeffnet dann bei Interaktion
## das zugehoerige Puzzle (overlay_scene/overlay_data aus dem Inspector).
## Schiffssystem-Kategorie dieser Stoerung (festes Dropdown). Muss gesetzt werden.
enum Category { NICHT_GESETZT, STROM, TREIBSTOFF, SCHILD, NAVIGATION }
@export var category: Category = Category.NICHT_GESETZT
@export var start_active: = false
@export var ignor_spawner: = false
var _active := false
var _solved := false
var _counted := false        ## ob diese Stoerung aktuell im Kategorie-Zaehler steckt
var _spawner: Node = null

func _setup() -> void:
	deactivate()
	if start_active:
		activate()
	if !ignor_spawner:
		_spawner = get_parent()
	

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
		GameState.set_system_broken(_category_name())

## Stoerung ausblenden + deaktivieren. (Zaehlt NICHT ab - das macht nur mark_solved.)
func deactivate() -> void:
	_active = false
	visible = false
	player_near = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	if label:
		label.visible = false

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
	# Journey-Score/Health/Log nur für Spawner-Störungen, nicht für Tutorial.
	if not ignor_spawner:
		GameState._report_malfunction_solved(_category_name())

## Nur reagieren, wenn aktiv. Meldet sich als "in Bearbeitung" beim Spawner.
func _action() -> void:
	if not _active or _solved:
		return
	if overlay_scene != "":
		SceneSwitcher.open_overlay_with_data(overlay_scene, {"malfunction": self}, true, false)
