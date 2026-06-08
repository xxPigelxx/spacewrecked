# HomePanel.gd — an Page_Home hängen
# Aktualisiert die Schiffsstatus-Labels automatisch.

extends Control

@onready var val_strom  :  = $VBoxContainer/HBoxContainer/ValStrom
@onready var val_treib  :  = $VBoxContainer/HBoxContainer2/ValTreib
@onready var val_schild :  = $VBoxContainer/HBoxContainer3/ValSchild
@onready var val_navi   :  = $VBoxContainer/HBoxContainer4/ValNavi

var _journey_box: VBoxContainer
var _phase_lbl: Label
var _time_lbl: Label
var _health_lbl: Label
var _solved_lbl: Label

func _ready() -> void:
	_build_journey_display()
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
	if _journey_box == null:
		return
	if not ("phase" in GameState):
		_journey_box.visible = false
		return
	var in_run: bool = GameState.phase == GameState.Phase.JOURNEY or GameState.phase == GameState.Phase.RESULTS
	_journey_box.visible = in_run
	if not in_run:
		return
	# Phase
	var phase_text := "REISE LÄUFT"
	if GameState.phase == GameState.Phase.RESULTS:
		phase_text = "BEENDET"
	_phase_lbl.text = "Status: %s" % phase_text
	# Restzeit mm:ss
	var total_s := int(GameState.time_left)
	@warning_ignore("integer_division")
	var mins := total_s / 60
	var secs := total_s % 60
	_time_lbl.text = "Zeit: %d:%02d" % [mins, secs]
	# Gesamt-Gesundheit
	var pct := int((GameState.health / GameState.max_health) * 100.0)
	_health_lbl.text = "Schiffshülle: %d%%" % pct
	# Gelöste Störungen
	_solved_lbl.text = "Repariert: %d" % GameState.malfunctions_solved

## Baut die Journey-Anzeige einmalig in die Home-VBox.
func _build_journey_display() -> void:
	var vbox := get_node_or_null("VBoxContainer")
	if vbox == null:
		return
	_journey_box = VBoxContainer.new()
	vbox.add_child(_journey_box)
	var sep := HSeparator.new()
	_journey_box.add_child(sep)
	_phase_lbl = Label.new();  _journey_box.add_child(_phase_lbl)
	_time_lbl = Label.new();   _journey_box.add_child(_time_lbl)
	_health_lbl = Label.new(); _journey_box.add_child(_health_lbl)
	_solved_lbl = Label.new(); _journey_box.add_child(_solved_lbl)
	_journey_box.visible = false

func _set_status(lbl: DyslexiaLabel, ok: bool, yes: String, no: String) -> void:
	lbl.text = yes if ok else no
	lbl.modulate = Color.WHITE
	lbl.add_theme_color_override("font_color", Color.GREEN if ok else Color.RED)
