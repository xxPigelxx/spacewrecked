extends VBoxContainer

## Wiederverwendbares Optionen-Panel (in Main- und Pause-Menue instanziert).
## Liest beim Oeffnen den aktuellen Zustand aus AudioServer/GameState und
## schreibt Aenderungen direkt zurueck. Werte gelten global (Autoloads) und
## bleiben darum szenen-uebergreifend erhalten.

@onready var _master: HSlider = $Master/Slider
@onready var _music: HSlider = $Music/Slider
@onready var _sfx: HSlider = $SFX/Slider
@onready var _dyslexia: CheckButton = $Dyslexie/Check
@onready var _stress: CheckButton = $Stress/Check

func _ready() -> void:
	_init_slider(_master, "Master")
	_init_slider(_music, "music")
	_init_slider(_sfx, "sfx")
	_dyslexia.button_pressed = GameState.dyslexia_enabled
	_stress.button_pressed = GameState.stress_from_health

	_master.value_changed.connect(func(v): _set_bus("Master", v))
	_music.value_changed.connect(func(v): _set_bus("music", v))
	_sfx.value_changed.connect(func(v): _set_bus("sfx", v))
	_dyslexia.toggled.connect(_on_dyslexia_toggled)
	_stress.toggled.connect(_on_stress_toggled)

## Slider auf die aktuelle Bus-Lautstaerke (linear 0..1) setzen.
func _init_slider(s: HSlider, bus_name: String) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	s.value = db_to_linear(AudioServer.get_bus_volume_db(idx)) if idx >= 0 else 1.0

func _set_bus(bus_name: String, v: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(v, 0.0001)))
	AudioServer.set_bus_mute(idx, v <= 0.0)

func _on_dyslexia_toggled(on: bool) -> void:
	GameState.dyslexia_enabled = on
	DyslexiaManager.accessibility = not on   # accessibility = Effekte AUS

func _on_stress_toggled(on: bool) -> void:
	GameState.stress_from_health = on
	if not on:
		DyslexiaManager.stress = 0.0
