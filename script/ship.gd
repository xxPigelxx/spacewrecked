extends Node2D
@onready var fier_sfx_1: AnimatedSprite2D = $FierSFX3
@onready var fier_sfx_2: AnimatedSprite2D = $FierSFX4

func _ready() -> void:
	fier_sfx_1.play("Fier_ainmation")
	fier_sfx_2.play("Fier_ainmation")
