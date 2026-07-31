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
@onready var _fullscreen: CheckButton = $FullScreen/CheckButton

func _ready() -> void:
	_init_slider(_master, "Master")
	_init_slider(_music, "music")
	_init_slider(_sfx, "sfx")
	_dyslexia.button_pressed = GameState.dyslexia_enabled
	_stress.button_pressed = GameState.stress_from_health
	_fullscreen.button_pressed = _is_fullscreen()

	_master.value_changed.connect(func(v): _set_bus("Master", v))
	_music.value_changed.connect(func(v): _set_bus("music", v))
	_sfx.value_changed.connect(func(v): _set_bus("sfx", v))
	_dyslexia.toggled.connect(_on_dyslexia_toggled)
	_stress.toggled.connect(_on_stress_toggled)
	_fullscreen.toggled.connect(_on_fullscreen_toggled)
	# Das Vollbild laesst sich auch ausserhalb des Panels verlassen — mit ESC,
	# im Browser zusaetzlich ueber dessen eigene Bedienung. Der Schalter erfaehrt
	# davon nichts, also beim Oeffnen des Panels neu abgleichen.
	visibility_changed.connect(_sync_fullscreen)

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


func _on_fullscreen_toggled(on: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED
	)

## Beide Vollbild-Varianten zaehlen als "an" — im HTML5-Export meldet der
## Browser die exklusive.
func _is_fullscreen() -> bool:
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN \
		or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN

## Im Hauptmenue wird der Eltern-Container ein- und ausgeblendet, nicht das
## Panel selbst — darum is_visible_in_tree() statt visible.
func _sync_fullscreen() -> void:
	if is_visible_in_tree():
		_fullscreen.set_pressed_no_signal(_is_fullscreen())
