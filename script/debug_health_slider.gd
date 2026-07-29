extends Node

## Debug-Regler fuer die Lebensanzeige. Schiebt GameState.health frei hin und her,
## damit sich Herzschlag-Tempo und beat_rate_curve testen lassen, ohne erst eine
## Runde kaputtspielen zu muessen.
##
## Baut seine Oberflaeche selbst auf: Skript an einen beliebigen Node in der
## Szene haengen, fertig. Nur im Debug-Build aktiv, taucht im HTML5-Release also
## nicht auf.
##
## Achtung: der Herzschlag laeuft nur in der Journey-Phase. Ausserhalb bewegt der
## Regler nur die Leiste, ohne Ton.

## Zum Abschalten, ohne den Node zu loeschen.
@export var enabled := true

var _slider: HSlider = null
var _label: Label = null


func _ready() -> void:
	if not enabled or not OS.is_debug_build():
		return

	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	box.offset_left = -220.0
	box.offset_top = 8.0
	box.offset_right = -8.0
	layer.add_child(box)

	_label = Label.new()
	box.add_child(_label)

	_slider = HSlider.new()
	_slider.min_value = 0.0
	_slider.max_value = GameState.max_health
	_slider.step = 1.0
	_slider.value = GameState.health
	box.add_child(_slider)

	_slider.value_changed.connect(_on_slider_changed)
	GameState.health_changed.connect(_on_health_changed)
	_on_health_changed(GameState.health)


## Setzt ueber dieselbe Funktion wie das Spiel selbst, damit der Stress-Wert
## mitzieht — sonst testet man das Tempo gegen einen Stresswert von vorhin.
func _on_slider_changed(value: float) -> void:
	GameState._set_health(value)


## Der Drain in der Journey senkt die Health jeden Frame, deshalb folgt der
## Regler dem echten Wert statt stehen zu bleiben.
func _on_health_changed(value: float) -> void:
	_label.text = "Health: %.0f / %.0f" % [value, GameState.max_health]
	_slider.set_value_no_signal(value)
