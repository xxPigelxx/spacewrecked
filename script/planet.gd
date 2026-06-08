extends Area2D

## Eindeutige Kennung des Planeten. Wird vom Detector beim Scannen gemeldet
## und vom NavPuzzle mit der Soll-Reihenfolge verglichen.
## Leer lassen = der Node-Name wird automatisch verwendet.
@export var planet_id: String = ""
var selection_scale := 1.0
## Dauer des Einblend-Pops in Sekunden.
@export var pop_time := 0.35

@onready var selection: Sprite2D = $SelectionSprite

var select_color = Color(0.3, 0.9, 1.0, 1.0)
var deselect_color =  Color(1.0, 0.2, 0.2, 1.0)

func _ready() -> void:
	if planet_id.is_empty():
		planet_id = name
	add_to_group("Planet")
	if selection:
		selection.visible = false
		selection_scale = selection.scale.x - 0.3
		selection.scale = Vector2.ZERO

## Auswahl anzeigen: skaliert mit befriedigendem Überschwingen hoch.
func select() -> void:
	selection.modulate = select_color
	if selection == null:
		return
	selection.visible = true
	selection.scale = Vector2.ZERO
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(selection, "scale", Vector2.ONE * selection_scale, pop_time).from(Vector2.ZERO)

## Auswahl entfernen: schrumpft wieder weg.
func deselect() -> void:
	selection.modulate = deselect_color
	if selection == null:
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(selection, "scale", Vector2.ZERO, pop_time * 0.7)
	tween.tween_callback(func(): selection.visible = false)
