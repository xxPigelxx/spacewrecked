extends Node2D
@onready var fier_sfx_1: AnimatedSprite2D = $FierSFX3
@onready var fier_sfx_2: AnimatedSprite2D = $FierSFX4
@onready var space_bg: Node2D = $SpaceBg

func _ready() -> void:
	start_flight()


func _play_fier_animation():
	fier_sfx_1.play("Fier_ainmation")
	fier_sfx_2.play("Fier_ainmation")

func _play_space_animation():
	space_bg.play_space_bg()

func start_flight():
	_play_fier_animation()
	_play_space_animation()
