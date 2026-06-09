extends Sprite2D
@onready var fier_sfx: AnimatedSprite2D = $FierSFX
@onready var fier_sfx_2: AnimatedSprite2D = $FierSFX2
@onready var fier_sfx_3: AnimatedSprite2D = $FierSFX3


func _ready() -> void:
	fier_sfx.play("Fier_ainmation")
	fier_sfx_2.play("Fier_ainmation")
	fier_sfx_3.play("Fier_ainmation")
