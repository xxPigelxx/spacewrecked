# HomePanel.gd — an Page_Home hängen
# Aktualisiert die Schiffsstatus-Labels automatisch.

extends Control

@onready var val_strom  :  = $VBoxContainer/HBoxContainer/ValStrom
@onready var val_treib  :  = $VBoxContainer/HBoxContainer2/ValTreib
@onready var val_schild :  = $VBoxContainer/HBoxContainer3/ValSchild
@onready var val_navi   :  = $VBoxContainer/HBoxContainer4/ValNavi

func _ready() -> void:
	GameState.ship_lights_changed.connect(func(_v): refresh())
	GameState.puzzle_solved.connect(func(_id): refresh())
	GameState.puzzle_unsolved.connect(func(_id): refresh())
	refresh()

func refresh() -> void:
	_set_status(val_strom,  GameState.is_puzzle_solved("cable1"),     "AKTIV",  "OFFLINE")
	_set_status(val_treib,  GameState.is_puzzle_solved("treibstoff"), "OK",     "LEER")
	_set_status(val_schild, GameState.is_puzzle_solved("schild"),     "AKTIV",  "OFFLINE")
	_set_status(val_navi,   GameState.ship_lights,                    "AKTIV",  "OFFLINE")

func _set_status(lbl: DyslexiaLabel, ok: bool, yes: String, no: String) -> void:
	lbl.text = yes if ok else no
	lbl.modulate = Color.WHITE
	lbl.add_theme_color_override("font_color", Color.GREEN if ok else Color.RED)
