extends CharacterBody2D

@onready var joystick: Node  = $"../Joystick"

@export var speed = 750
@export var only_move_on_solved = true

func _physics_process(_delta: float) -> void:
	if only_move_on_solved:
		if GameState.is_system_broken("treibstoff") or GameState.is_system_broken("strom"):
			return
	var direction = -joystick.posVector.normalized()
	if direction:
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()
