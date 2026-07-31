extends Node

## Debug-Regler fuer den Stresswert. Setzt DyslexiaManager.stress direkt, damit
## sich die Handbuchseiten auf jeder Stufe ansehen lassen, ohne erst Schaden
## nehmen zu muessen.
##
## Baut seine Oberflaeche selbst auf: Skript an einen beliebigen Node der Szene
## haengen, fertig. Nur im Debug-Build aktiv, taucht im HTML5-Release also nicht
## auf.
##
## Unterschied zu debug_health_slider.gd: der geht ueber die Gesundheit und
## damit ueber den Umweg der Journey-Formel. Hier wird der Stresswert selbst
## gesetzt — auch ausserhalb der Journey-Phase.

## Zum Abschalten, ohne den Node zu loeschen.
@export var enabled := true

var _slider: HSlider = null
var _label: Label = null
var _hold: CheckBox = null
## Urzustand von GameState.stress_from_health, damit "festhalten" ihn beim
## Loslassen nicht auf einen erfundenen Wert setzt.
var _hold_restore := true


func _ready() -> void:
	if not enabled or not OS.is_debug_build():
		return

	var layer := CanvasLayer.new()
	layer.layer = 100
	# Soll auch bedienbar bleiben, wenn SceneSwitcher die Szene fuer ein Overlay
	# einfriert — sonst laesst sich das offene Handbuch nicht durchregeln.
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_TOP_LEFT)
	box.offset_left = 8.0
	box.offset_top = 8.0
	box.offset_right = 268.0
	layer.add_child(box)

	_label = Label.new()
	box.add_child(_label)

	_slider = HSlider.new()
	_slider.min_value = 0.0
	_slider.max_value = 100.0
	# Gleiche Stufung wie GameManager.STRESS_STEP: feiner einzustellen bringt
	# nichts, das Spiel selbst rastet auch in 5er-Schritten.
	_slider.step = 5.0
	_slider.value = DyslexiaManager.stress
	box.add_child(_slider)

	_hold = CheckBox.new()
	_hold.text = "Stress festhalten"
	box.add_child(_hold)

	var access := CheckBox.new()
	access.text = "Effekte aus (Vergleich)"
	access.button_pressed = DyslexiaManager.accessibility
	box.add_child(access)

	_slider.value_changed.connect(_on_slider_changed)
	_hold.toggled.connect(_on_hold_toggled)
	access.toggled.connect(_on_accessibility_toggled)
	DyslexiaManager.stress_changed.connect(_on_stress_changed)
	_on_stress_changed(DyslexiaManager.stress)


func _on_slider_changed(value: float) -> void:
	DyslexiaManager.stress = value


## Ohne das Abschalten setzt _apply_stress_from_health() den Regler in der
## Journey jeden Frame wieder auf den Wert aus der Gesundheit zurueck.
func _on_hold_toggled(on: bool) -> void:
	if on:
		_hold_restore = GameState.stress_from_health
		GameState.stress_from_health = false
	else:
		GameState.stress_from_health = _hold_restore


func _on_accessibility_toggled(on: bool) -> void:
	DyslexiaManager.accessibility = on


## Solange das Spiel den Stress steuert, folgt der Regler dem echten Wert.
func _on_stress_changed(value: float) -> void:
	var suffix := "  (festgehalten)" if _hold.button_pressed else ""
	_label.text = "Stress: %d%s" % [int(value), suffix]
	_slider.set_value_no_signal(value)
