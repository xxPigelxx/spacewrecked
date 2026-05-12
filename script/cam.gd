extends Area2D

@onready var camera_2d: Camera2D = $"../Camera2D"

func _on_mouse_entered() -> void:
	print("camera")
	camera_2d.position = Vector2(camera_2d.position.x, -1080)
