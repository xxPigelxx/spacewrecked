extends Node2D

## Zeichnet Ringe um bestätigte Planeten. Vom NavPuzzle gesteuert.
## Liegt unter Space/planets, also im selben Koordinatenraum wie die Planeten.

@export var radius := 90.0
@export var ring_width := 6.0
@export var ring_color := Color(0.3, 0.9, 1.0, 1.0)

var _centers: PackedVector2Array = []

func set_centers(centers: PackedVector2Array) -> void:
	_centers = centers
	queue_redraw()

func _draw() -> void:
	for c in _centers:
		draw_arc(c, radius, 0.0, TAU, 48, ring_color, ring_width, true)
