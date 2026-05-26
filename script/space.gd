extends CharacterBody2D

@onready var joystick: Node  = $"../Joystick"

@export var speed = 750

func _physics_process(_delta: float) -> void:
	if !GameState.is_puzzle_solved("treibstoff") or !GameState.is_puzzle_solved("cable1"):
		return
	var direction = -joystick.posVector.normalized()
	if direction:
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()
