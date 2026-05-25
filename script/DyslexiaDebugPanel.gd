# DyslexiaDebugPanel.gd
# F2 im Spiel drücken zum öffnen/schliessen.

extends CanvasLayer

const TOGGLE_KEY := KEY_F2

@onready var panel          : PanelContainer = $Panel
@onready var stress_slider  : HSlider        = $Panel/VBox/StressRow/StressSlider
@onready var stress_label   : Label          = $Panel/VBox/StressRow/StressLabel
@onready var vanish_slider  : HSlider        = $Panel/VBox/VanishRow/VanishSlider
@onready var vanish_label   : Label          = $Panel/VBox/VanishRow/VanishLabel
@onready var access_check   : CheckButton    = $Panel/VBox/AccessRow/AccessCheck
@onready var preview_label  : RichTextLabel  = $Panel/VBox/Preview

@onready var swap_slider      : HSlider = $Panel/VBox/SwapRow/SwapSlider
@onready var swap_label       : Label   = $Panel/VBox/SwapRow/SwapLabel
@onready var drift_amp_slider : HSlider = $Panel/VBox/DriftAmpRow/DriftAmpSlider
@onready var drift_amp_label  : Label   = $Panel/VBox/DriftAmpRow/DriftAmpLabel
@onready var drift_freq_slider : HSlider = $Panel/VBox/DriftFreqRow/DriftFreqSlider
@onready var drift_freq_label  : Label   = $Panel/VBox/DriftFreqRow/DriftFreqLabel
@onready var size_var_slider  : HSlider = $Panel/VBox/SizeVarRow/SizeVarSlider
@onready var size_var_label   : Label   = $Panel/VBox/SizeVarRow/SizeVarLabel
@onready var river_slider     : HSlider = $Panel/VBox/RiverRow/RiverSlider
@onready var river_label      : Label   = $Panel/VBox/RiverRow/RiverLabel
@onready var mirror_slider    : HSlider = $Panel/VBox/MirrorRow/MirrorSlider
@onready var mirror_label     : Label   = $Panel/VBox/MirrorRow/MirrorLabel

# Preview-Effektwerte (lokal für die Vorschau im Panel)
var _swap_pct   : float = 40.0
var _drift_amp  : float = 6.0
var _drift_freq : float = 1.5
var _size_var   : float = 2.0
var _river_gap  : float = 3.0
var _mirror_pct : float = 0.0
var _scramble_pct  : float = 0.0
var _crowd_pct     : float = 0.0
var _transpose_pct : float = 0.0
var _shake_amp     : float = 0.0
var _tornado_radius: float = 0.0
var _tornado_freq  : float = 1.0
var _pulse_freq    : float = 0.0

func _ready() -> void:
	panel.visible = false
	stress_slider.value  = DyslexiaManager.stress
	vanish_slider.value  = DyslexiaManager.global_vanish
	access_check.button_pressed = DyslexiaManager.accessibility
	_update_labels()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == TOGGLE_KEY:
		panel.visible = not panel.visible

# ── Global ──────────────────────────────────────────────
func _on_stress_changed(value: float) -> void:
	DyslexiaManager.stress = value
	_update_labels()
	_update_preview()

func _on_vanish_changed(value: float) -> void:
	DyslexiaManager.global_vanish = value
	_update_labels()
	_update_preview()

func _on_access_toggled(on: bool) -> void:
	DyslexiaManager.accessibility = on
	_update_preview()

# ── Preview-Effekte ──────────────────────────────────────
func _on_swap_changed(value: float) -> void:
	_swap_pct = value
	swap_label.text = "%d%%" % int(value)
	_update_preview()

func _on_drift_amp_changed(value: float) -> void:
	_drift_amp = value
	drift_amp_label.text = "%.1f" % value
	_update_preview()

func _on_drift_freq_changed(value: float) -> void:
	_drift_freq = value
	drift_freq_label.text = "%.1f" % value
	_update_preview()

func _on_size_var_changed(value: float) -> void:
	_size_var = value
	size_var_label.text = "%.1f" % value
	_update_preview()

func _on_river_changed(value: float) -> void:
	_river_gap = value
	river_label.text = "%.1f" % value
	_update_preview()

func _on_mirror_changed(value: float) -> void:
	_mirror_pct = value
	mirror_label.text = "%d%%" % int(value)
	_update_preview()

func _on_scramble_changed(value: float) -> void:
	_scramble_pct = value
	$Panel/VBox/ScrambleRow/ScrambleLabel.text = "%d%%" % int(value)
	_update_preview()

func _on_crowd_changed(value: float) -> void:
	_crowd_pct = value
	$Panel/VBox/CrowdRow/CrowdLabel.text = "%d%%" % int(value)
	_update_preview()

func _on_transpose_changed(value: float) -> void:
	_transpose_pct = value
	$Panel/VBox/TransposeRow/TransposeLabel.text = "%d%%" % int(value)
	_update_preview()

func _on_shake_changed(value: float) -> void:
	_shake_amp = value
	$Panel/VBox/ShakeRow/ShakeLabel.text = "%.1f" % value
	_update_preview()

func _on_tornado_radius_changed(value: float) -> void:
	_tornado_radius = value
	$Panel/VBox/TornadoRadiusRow/TornadoRadiusLabel.text = "%.1f" % value
	_update_preview()

func _on_tornado_freq_changed(value: float) -> void:
	_tornado_freq = value
	$Panel/VBox/TornadoFreqRow/TornadoFreqLabel.text = "%.1f" % value
	_update_preview()

func _on_pulse_changed(value: float) -> void:
	_pulse_freq = value
	$Panel/VBox/PulseRow/PulseLabel.text = "%.1f" % value
	_update_preview()


# —— Farben ————————————————————————————————————
func _on_color_swap_changed(color: Color) -> void:
	DyslexiaManager.color_swap = color
	_update_preview()

func _on_color_scramble_changed(color: Color) -> void:
	DyslexiaManager.color_scramble = color
	_update_preview()

func _on_color_transpose_changed(color: Color) -> void:
	DyslexiaManager.color_transpose = color
	_update_preview()

func _on_color_pulse_changed(color: Color) -> void:
	DyslexiaManager.color_pulse = color
	_update_preview()

# ── Intern ───────────────────────────────────────────────
func _update_labels() -> void:
	stress_label.text = "%d%%" % int(DyslexiaManager.stress)
	vanish_label.text = "%d%%" % int(DyslexiaManager.global_vanish)

func _update_preview() -> void:
	preview_label.bbcode_enabled = true
	preview_label.text = DyslexiaManager.process_text(
		"Der Zugangscode lautet neun sechs zwei vier.",
		9999, 0.0,
		_swap_pct, _drift_amp, _drift_freq,
		_size_var, _river_gap, _mirror_pct,
		_scramble_pct, _crowd_pct, _transpose_pct,
		_shake_amp, _tornado_radius, _tornado_freq, _pulse_freq
	)
