extends Node2D
@onready var fier_sfx: AnimatedSprite2D = $FierSFX
@onready var fier_sfx_2: AnimatedSprite2D = $FierSFX2
@onready var fier_sfx_3: AnimatedSprite2D = $FierSFX3
@onready var astriod_sprite: Sprite2D = $AstriodSprite

@export var rotation_speed: = -3

func _ready() -> void:
	fier_sfx.play("Fier_ainmation")
	fier_sfx_2.play("Fier_ainmation")
	fier_sfx_3.play("Fier_ainmation")

func _process(delta: float) -> void:
	astriod_sprite.rotation += delta * rotation_speed

func move_to_point(target_pos: Vector2):
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, 1.5)
	await tween.finished
	#AudioManager.play_sfx("res://resources/assets/sfx/Explosions - Sound Effects/Explosions - Sound Effects/Small_Explosion_3.wav")
	queue_free()
