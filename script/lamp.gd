extends Sprite2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@export var active_color: Color = Color.WHITE
@export var disabled_color: Color = Color.GRAY

func _ready() -> void:
	animated_sprite_2d.visible = false
	set_active(false)

func set_active(value: bool = false) -> void:
	animated_sprite_2d.visible = value

	if value:
		modulate = active_color
		animated_sprite_2d.play("default")
	else:
		animated_sprite_2d.stop()
		modulate = disabled_color
