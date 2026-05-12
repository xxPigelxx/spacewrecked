extends Sprite2D

@onready var vertical: VSlider = $"../Vertical"
@onready var horizontal: VSlider = $"../Horisontal"

# How far you can "look" from the center
var movement_range := Vector2(4200/2 - 1920/2, 3300/2 - 1080/2)

# Center position of the sprite
var center := Vector2.ZERO

# Smooth movement target
var target_position := Vector2.ZERO

func _ready() -> void:
	# Save starting position as center
	center = position
	target_position = position
	
	# Set slider limits (small range = telescope feeling)
	vertical.min_value = -movement_range.y
	vertical.max_value = movement_range.y
	
	horizontal.min_value = -movement_range.x
	horizontal.max_value = movement_range.x
	
	# Optional: start sliders in the middle
	vertical.value = 0
	horizontal.value = 0


func _process(delta: float) -> void:
	# Smoothly move towards target (feels like camera/telescope)
	position = position.lerp(target_position, 5 * delta)


func _on_vertical_value_changed(value: float) -> void:
	target_position.y = center.y + value


func _on_horisontal_value_changed(value: float) -> void:
	target_position.x = center.x + value
