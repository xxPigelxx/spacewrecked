extends Node

## Navigations-Puzzle: Planeten in der richtigen Reihenfolge scannen.
## Die Soll-Reihenfolge steht (verzerrt) im Manual — der Spieler muss sie lesen.
## Richtiger Scan  -> Linie wächst animiert zum Planeten.
## Falscher Scan   -> Linie springt zurück zum letzten korrekten Punkt.

## Wird einmal ausgelöst, wenn das Puzzle gelöst ist (Schleife geschlossen).
## Im Editor verbindbar — z.B. mit einem Button, Sound, Schiffsstart usw.

@export var category := "navigation"
## Soll-Reihenfolge der planet_id-Werte. An die Manual-Seite anpassen.
@export var correct_order: Array[String] = ["Earth", "BlueMoon", "Saturn", "Station"]
@export var draw_speed := 1200.0  ## Pixel pro Sekunde, mit der die Linie wächst

@export_group("Gewinn-Animation")
@export var pulse_duration := 2.0          ## Sekunden Pulsieren vor Grün
@export var pulse_period := 0.6            ## Dauer eines Ein-/Ausblendzyklus
@export var pulse_min_alpha := 0.15        ## dunkelster Punkt beim Pulsieren
@export var win_color := Color(0.2, 1.0, 0.3, 1.0)  ## Endfarbe (grün)

@export_group("Fehler-Animation")
@export var reject_color := Color(1.0, 0.2, 0.2, 1.0)  ## Linienfarbe bei falschem Planeten (rot)
@export var reject_hold := 0.35  ## Sekunden, die der falsche Planet ausgewählt bleibt, bevor er rot wird

@onready var detector: Area2D = $Detector
@onready var line: Line2D = $Space/planets/NavLine
@onready var planets_root: Node2D = $Space/planets
@onready var start_button: Button = $StartShipBt
@onready var return_bt: Button = $ReturnBt
@onready var error_code: Node2D = $ErrorCode

var malfunction = null

var _step := 0                       ## wie viele Planeten korrekt bestätigt sind
var _confirmed_points: PackedVector2Array = []
var _confirmed_planets: Array[Node2D] = []  ## bestätigte Planeten-Nodes (parallel zu _confirmed_points)
var _target_point: Vector2           ## wohin die Linie gerade wächst
var _animating := false
var _closing := false                ## true während die Schleife geschlossen wird
var _want_close := false             ## true wenn nach dem letzten Segment geschlossen werden soll
var _rejecting := false              ## true während der Fehler-Sequenz
var _reject_retracting := false      ## true wenn die rote Linie zurückschrumpft
var _wrong_planet: Node2D = null     ## der gerade abgelehnte Planet
var _retract_target: Vector2         ## Punkt, zu dem die rote Linie zurückkehrt
var _reject_hold_timer := 0.0        ## zählt die Haltezeit, bevor der falsche Planet rot wird
var _base_line_color: Color          ## ursprüngliche Linienfarbe zum Wiederherstellen
var _solved := false

func _ready() -> void:
	detector.planet_scanned.connect(_on_planet_scanned)
	line.clear_points()
	_base_line_color = line.default_color

func _process(delta: float) -> void:
	if _rejecting:
		_process_reject(delta)
		return
	if not _animating:
		return
	# Letzten (wachsenden) Punkt Richtung Ziel bewegen
	var idx := line.get_point_count() - 1
	var cur := line.get_point_position(idx)
	var next := cur.move_toward(_target_point, draw_speed * delta)
	line.set_point_position(idx, next)
	if next.is_equal_approx(_target_point):
		_animating = false
		if _closing:
			_closing = false
			# Temporären Wachstumspunkt entfernen und Schleife schließen
			line.remove_point(line.get_point_count() - 1)
			line.closed = true
			_win()
		else:
			_confirmed_points.append(_target_point)
			if _want_close:
				_want_close = false
				_close_loop()

## Bewegt den wachsenden/schrumpfenden Punkt während der Fehler-Sequenz.
func _process_reject(delta: float) -> void:
	var idx := line.get_point_count() - 1
	var cur := line.get_point_position(idx)
	var goal := _retract_target if _reject_retracting else _target_point
	var next := cur.move_toward(goal, draw_speed * delta)
	line.set_point_position(idx, next)
	if not next.is_equal_approx(goal):
		return
	if not _reject_retracting:
		# Ziel erreicht: kurz halten, damit der Auswahl-Pop sichtbar ist
		# (wichtig beim ersten Planeten, wo die Linie keine Strecke hat)
		_reject_hold_timer += delta
		if _reject_hold_timer < reject_hold:
			return
		# rot färben, Planet abwählen, dann zurückziehen
		line.default_color = reject_color
		if _wrong_planet and _wrong_planet.has_method("deselect"):
			_wrong_planet.deselect()
		_reject_retracting = true
	else:
		# Zurückgezogen: temporären Punkt entfernen, Farbe & Zustand wiederherstellen
		line.remove_point(line.get_point_count() - 1)
		line.default_color = _base_line_color
		_rejecting = false
		_reject_retracting = false
		_wrong_planet = null
		_reject_hold_timer = 0.0

func _on_planet_scanned(planet_id: String) -> void:
	if _solved or _animating or _rejecting:
		return
	if planet_id == correct_order[_step]:
		_advance(planet_id)
	else:
		_reject(planet_id)

func _advance(planet_id: String) -> void:
	var planet := planets_root.get_node_or_null(planet_id)
	if planet == null:
		push_warning("NavPuzzle: Planet '%s' nicht unter planets gefunden." % planet_id)
		return
	var dest: Vector2 = planet.position  # lokale Position im selben Raum wie die Linie

	# Auswahl-Sprite mit Pop einblenden und Planet als bestätigt merken
	if planet.has_method("select"):
		planet.select()
	_confirmed_planets.append(planet)

	if _confirmed_points.is_empty():
		# Erster Planet: Startpunkt direkt setzen, keine Animation
		line.add_point(dest)
		_confirmed_points.append(dest)
	else:
		# Wachsenden Punkt am letzten bestätigten Punkt starten
		line.add_point(_confirmed_points[_confirmed_points.size() - 1])
		_target_point = dest
		_animating = true

	_step += 1
	if _step >= correct_order.size():
		if _animating:
			_want_close = true   # erst schließen, wenn das letzte Segment fertig ist
		else:
			_close_loop()        # letzter Planet war ohne Animation (Sonderfall)

func _close_loop() -> void:
	# Letzte Linie zurück zum ersten Planeten wachsen lassen, dann schließen
	if _confirmed_points.size() < 2:
		_win()
		return
	_closing = true
	line.add_point(_confirmed_points[_confirmed_points.size() - 1])
	_target_point = _confirmed_points[0]
	_animating = true

func _reject(planet_id: String) -> void:
	var planet := planets_root.get_node_or_null(planet_id)
	if planet == null:
		push_warning("NavPuzzle: Planet '%s' nicht unter planets gefunden." % planet_id)
		return
	var dest: Vector2 = planet.position

	# Falscher Planet wird trotzdem ausgewählt (Pop)
	if planet.has_method("select"):
		planet.select()
	_wrong_planet = planet

	if _confirmed_points.is_empty():
		# Noch kein Startpunkt: Linie wächst vom Planeten und zieht sich dorthin zurück
		line.add_point(dest)
		_retract_target = dest
	else:
		var anchor: Vector2 = _confirmed_points[_confirmed_points.size() - 1]
		line.add_point(anchor)
		_retract_target = anchor

	_target_point = dest
	_rejecting = true
	_reject_retracting = false
	_reject_hold_timer = 0.0

func _reset_to_last_correct() -> void:
	# Optional: Stress erhöhen, wenn der Spieler sich verliest
	# DyslexiaManager.stress += 15.0
	line.closed = false
	line.clear_points()
	for p in _confirmed_points:
		line.add_point(p)
	# Überzählige Planeten wieder abwählen und Liste kürzen
	while _confirmed_planets.size() > _confirmed_points.size():
		var lost: Node2D = _confirmed_planets.pop_back()
		if lost and lost.has_method("deselect"):
			lost.deselect()
	_step = _confirmed_points.size()

## Zentrale Gewinn-Funktion — wird genau einmal ausgeführt.
func _win() -> void:
	if _solved:
		return
	_solved = true
	if malfunction:
		malfunction.mark_solved()
	error_code.lamp_flash()
	AudioManager.play_success()
	_play_win_animation()
	return_bt.disabled = true
	

## Linie pulsiert x Sekunden, wird dann grün, Start-Button erscheint.
func _play_win_animation() -> void:
	var tween := create_tween()
	# Pulsieren: Alpha hin und her, so oft wie in pulse_duration passt
	var cycles: int = max(1, int(round(pulse_duration / pulse_period)))
	var half: float = pulse_period * 0.5
	for i in cycles:
		tween.tween_property(line, "modulate:a", pulse_min_alpha, half)
		tween.tween_property(line, "modulate:a", 1.0, half)
	# Danach: voll sichtbar, grün einfärben und Button freischalten
	tween.tween_property(line, "modulate:a", 1.0, 0.0)
	tween.tween_property(line, "default_color", win_color, 0.4)
	tween.tween_callback(_enable_start_button)

func _enable_start_button() -> void:
	start_button.visible = true
	start_button.disabled = false

func _on_return_pressed() -> void:
	SceneSwitcher.close_overlay_scene()

func _on_start_pressed() -> void:
	# Start-Schiff Button: Journey-Phase + Messfenster starten.
	GameState.start_journey()
	SceneSwitcher.close_overlay_scene()
