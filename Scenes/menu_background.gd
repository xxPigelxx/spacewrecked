extends Node2D

@onready var path_follow_2d: PathFollow2D = $Path2D/PathFollow2D

@export var path_speed := 10


func _process(delta: float) -> void:
	path_follow_2d.progress += delta * path_speed
