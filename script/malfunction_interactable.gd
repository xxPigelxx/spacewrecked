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
@export var astoroid: = false
## Meteor-Warnung (nur wenn astoroid = true): ein Alarm-Sound wird warning_lead_time
## Sekunden VOR dem Anflug abgespielt, damit der Spieler den Einschlag kommen hoert.
## warning_sound ist bewusst als Pfad exportiert, damit der Sound spaeter leicht
## gegen einen echten Alarm/Sirene getauscht werden kann.
@export var warning_sound: String = "res://resources/assets/sfx/Interface_Bleeps_Wav/Bleep_06.wav"
@export var warning_beeps: int = 3       ## wie oft der Alarm-Sound in der Vorlaufzeit ertoent
@export var warning_lead_time: float = 1.0  ## Sekunden Alarm vor dem Anflug (+1.5 s Flug = Gesamtwarnung)

@onready var ship: Node2D = $"../../../Ship"

const ASTROID = preload("uid://bdb3yq2bckj6b")

var _solved := false
var _counted := false        ## ob diese Stoerung aktuell im Kategorie-Zaehler steckt
var _spawned := false        ## ob try_spawn sie in dieser Journey schon aktiviert hat
var _was_blocked := false    ## true, sobald ihr Spawn wegen belegter Kategorie verschoben wurde
var _release_time := -1.0    ## elapsed-Zeitpunkt, ab dem nach dem Freiwerden gespawnt werden darf (-1 = noch nicht gesetzt)


func _setup() -> void:
	active = false
	visible = false
	if label:
		label.visible = false
	if phase == Phase.TUTORIAL:
		activate()              # Tutorial: sofort sichtbar, self-managed
	else:
		# Unsichtbar heisst auch: nicht mithoeren. Journey-Stoerungen liegen exakt
		# auf den Tutorial-Stoerungen; ihr body_exited wuerde sonst den Prompt der
		# sichtbaren Stoerung darunter loeschen.
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)
		GameState.register_malfunction(self)  # Journey: wartet auf spawn_time

## Beim Verlassen der Szene austragen, damit GameState keine toten Referenzen behaelt.
func _exit_tree() -> void:
	if is_instance_valid(GameState):
		GameState.unregister_malfunction(self)

## Vom GameState pro Frame aufgerufen. Aktiviert sich, sobald elapsed >= spawn_time —
## aber nie, solange eine ANDERE Stoerung derselben Kategorie noch aktiv ist.
## Ist die Kategorie belegt, wird gewartet, bis die andere geloest ist, plus ein
## kleiner Zufalls-Offset (10–20 s), damit nicht sofort die naechste losgeht.
func try_spawn(elapsed: float) -> void:
	if _spawned or active or _solved:
		return
	if elapsed < spawn_time:
		return

	# Nie zwei Stoerungen derselben Kategorie gleichzeitig: ist bereits eine andere
	# aktiv, verschieben wir den Spawn und merken uns, dass wir blockiert waren.
	if GameState.is_category_active(_category_name(), self):
		_was_blocked = true
		_release_time = -1.0
		return

	# Kategorie ist frei. Falls wir vorher blockiert waren, erst einen kleinen
	# Offset nach dem Freiwerden abwarten (einmalig setzen, dann herunterzaehlen).
	if _was_blocked:
		if _release_time < 0.0:
			_release_time = elapsed + randf_range(10.0, 20.0)
			return
		if elapsed < _release_time:
			return

	_spawned = true
	activate()

## Vor Journey-Start zuruecksetzen, damit erneute Laeufe sauber starten.
func reset_for_journey() -> void:
	_spawned = false
	_solved = false
	_was_blocked = false
	_release_time = -1.0
	deactivate()
	

## Oeffentlicher Zugriff auf den Kategorie-String (fuer GameState.is_category_active).
func get_category_name() -> String:
	return _category_name()

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
	if active:
		return
	active = true
	_solved = false
	if astoroid:
		# Erst den Alarm (Vorwarnung), dann den Anflug — Spieler hoert den Meteor kommen.
		await _play_meteor_warning()
		var new_asteroid = ASTROID.instantiate()
		get_tree().current_scene.add_child(new_asteroid)

		new_asteroid.global_position = Vector2(2000, global_position.y + randf_range(-500,500))

		# Auf Ankunft warten
		await new_asteroid.move_to_point(global_position)
		
		await ship.shake_ship()
		
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
## Spielt vor dem Meteor-Anflug einen Alarm-Sound (warning_beeps mal, gleichmaessig
## ueber warning_lead_time verteilt) und wartet dabei die volle Vorlaufzeit ab.
## Danach folgt der ~1.5 s Anflug in activate() -> Gesamtwarnung ~2.5 s.
func _play_meteor_warning() -> void:
	var beeps: int = max(1, warning_beeps)
	var gap: float = warning_lead_time / float(beeps)
	for i in beeps:
		if warning_sound != "" and is_instance_valid(AudioManager):
			AudioManager.play_sfx(warning_sound)
		if gap > 0.0:
			await get_tree().create_timer(gap).timeout

## Stoerung ausblenden + deaktivieren.
## Falls die Stoerung noch gezaehlt war (aber nicht geloest), Zaehler bereinigen,
## damit _counted konsistent bleibt (z.B. bei Reset/begin oder clear_all).
func deactivate() -> void:
	active = false
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
	return active and not _solved

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
	else:
		# Tutorial: baut die Lebensleiste schrittweise von 0 auf voll auf.
		GameState.report_tutorial_repair()

## Nur reagieren, wenn aktiv. Meldet sich als "in Bearbeitung" beim Spawner.
func _action() -> void:
	if not active or _solved:
		return
	if overlay_scene != "":
		# freeze_scene = false: das Schiff laeuft hinter dem Raetsel weiter, damit
		# Lebensleiste und Herzschlag mit dem echten (weiterlaufenden) Lebensverlust
		# Schritt halten.
		SceneSwitcher.open_overlay_with_data(overlay_scene, {"malfunction": self}, true, false, false, false)
