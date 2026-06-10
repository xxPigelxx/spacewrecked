# HomePanel.gd — an Page_Home hängen
# Aktualisiert die Schiffsstatus-Labels automatisch.

extends Control

@onready var val_strom  :  = $VBoxContainer/HBoxContainer/ValStrom
@onready var val_treib  :  = $VBoxContainer/HBoxContainer2/ValTreib
@onready var val_schild :  = $VBoxContainer/HBoxContainer3/ValSchild
@onready var val_navi   :  = $VBoxContainer/HBoxContainer4/ValNavi

@onready var _phase_lbl:= $VBoxContainer/Status2
@onready var _time_lbl:= $VBoxContainer/HBoxContainer5/L5
@onready var _health_lbl:= $VBoxContainer/HBoxContainer5/L4
@onready var _solved_lbl:= $VBoxContainer/HBoxContainer7/L4

func _ready() -> void:
	_show_journey_display(false)
	GameState.ship_lights_changed.connect(func(_v): refresh())
	if GameState.has_signal("health_changed"):
		GameState.health_changed.connect(func(_v): refresh())
	if GameState.has_signal("malfunctions_solved_changed"):
		GameState.malfunctions_solved_changed.connect(func(_c): refresh())
	if GameState.has_signal("broken_systems_changed"):
		GameState.broken_systems_changed.connect(func(): refresh())
	if GameState.has_signal("time_changed"):
		GameState.time_changed.connect(func(_t): refresh())
	if GameState.has_signal("phase_changed"):
		GameState.phase_changed.connect(func(_p): refresh())
	refresh()

func refresh() -> void:
	# Vier Systeme durchgehend über die Counter: gestört = OFFLINE, sonst AKTIV.
	# (Setup -> alle OK; nur aktive Malfunctions setzen ein System offline.)
	_set_status(val_strom,  not GameState.is_system_broken("strom"),      "AKTIV", "OFFLINE")
	_set_status(val_treib,  not GameState.is_system_broken("treibstoff"), "OK",    "LEER")
	_set_status(val_schild, not GameState.is_system_broken("schild"),     "AKTIV", "OFFLINE")
	_set_status(val_navi,   not GameState.is_system_broken("navigation"), "AKTIV", "OFFLINE")
	_refresh_journey()

func _is_journey() -> bool:
	return ("phase" in GameState) and GameState.phase == GameState.Phase.JOURNEY

## Zeigt Journey-Status, Restzeit, Gesamt-Schiffsgesundheit und gelöste Störungen.
func _refresh_journey() -> void:
	if not ("phase" in GameState):
		_show_journey_display(false)
		return
	var in_run: bool = GameState.phase == GameState.Phase.JOURNEY or GameState.phase == GameState.Phase.RESULTS
	_show_journey_display(in_run)
	if not in_run:
		return
	# Phase
	var phase_text := "REISE LÄUFT"
	if GameState.phase == GameState.Phase.RESULTS:
		phase_text = "BEENDET"
	_set_label_text(_phase_lbl, "Status: %s" % phase_text)
	# Restzeit mm:ss
	var total_s := int(GameState.time_left)
	@warning_ignore("integer_division")
	var mins := total_s / 60
	var secs := total_s % 60
	_set_label_text(_time_lbl, "Zeit: %d:%02d" % [mins, secs])
	# Gesamt-Gesundheit
	var pct := int((GameState.health / GameState.max_health) * 100.0)
	_set_label_text(_health_lbl, "Schiffshülle: %dw" % pct)
	# Gelöste Störungen
	_set_label_text(_solved_lbl, "Repariert: %d" % GameState.malfunctions_solved)

## Baut die Journey-Anzeige einmalig in die Home-VBox.
func _show_journey_display(val = true) -> void:
	_phase_lbl.visible = val
	_health_lbl.visible = val
	_time_lbl.visible = val
	_solved_lbl.visible = val

func _set_status(lbl, ok: bool, yes: String, no: String) -> void:
	_set_label_text(lbl, yes if ok else no)
	lbl.modulate = Color.WHITE
	lbl.add_theme_color_override("font_color", Color.GREEN if ok else Color.RED)

## Setzt Text korrekt — bei DyslexiaLabel über set_source_text, sonst .text.
func _set_label_text(lbl, value: String) -> void:
	if lbl == null:
		return
	if lbl.has_method("set_source_text"):
		lbl.set_source_text(value)
	else:
		lbl.text = value
