extends CharacterBody2D

@export var speed := 300.0

func _physics_process(delta: float) -> void:
	var direction = Vector2.ZERO

	# Input movement
	if Input.is_action_pressed("move_right"):
		direction.x += 1
		
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
		
	if Input.is_action_pressed("move_down"):
		direction.y += 1
		
	if Input.is_action_pressed("move_up"):
		direction.y -= 1

	# Normalize so diagonal isn't faster
	direction = direction.normalized()

	# Apply movement
	velocity = direction * speed

	move_and_slide()
