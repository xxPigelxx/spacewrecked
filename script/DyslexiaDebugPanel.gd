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

func _ready() -> void:
	panel.visible = false
	stress_slider.value  = DyslexiaManager.stress
	vanish_slider.value  = DyslexiaManager.global_vanish
	access_check.button_pressed = DyslexiaManager.accessibility
	_update_labels()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == TOGGLE_KEY:
		panel.visible = not panel.visible

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

func _update_labels() -> void:
	stress_label.text = "%d%%" % int(DyslexiaManager.stress)
	vanish_label.text = "%d%%" % int(DyslexiaManager.global_vanish)

func _update_preview() -> void:
	preview_label.bbcode_enabled = true
	preview_label.text = DyslexiaManager.process_text(
		"Der Zugangscode lautet neun sechs zwei vier.",
		9999, 0.0, 40.0, 6.0, 1.5, 2.0, 3.0, 0.0
	)
