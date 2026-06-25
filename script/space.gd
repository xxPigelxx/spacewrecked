extends CharacterBody2D

@onready var joystick: Node  = $"../Joystick"

@export var speed = 750
@export var only_move_on_solved = true


## Parallax: Hintergrund bewegt sich mit einem Bruchteil der Space-Bewegung.
## 0 = steht still, 1 = bewegt sich wie die Planeten. 0.2-0.4 gibt Tiefe.
@export var parallax_background: Node2D
@export var parallax_factor := 0.2

var _start_pos: Vector2
var _bg_start_pos: Vector2

func _ready() -> void:
	_start_pos = position
	if parallax_background:
		_bg_start_pos = parallax_background.position

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
	# Parallax: Hintergrund einen Bruchteil mitziehen
	if parallax_background:
		var moved := position - _start_pos
		parallax_background.position = _bg_start_pos + moved * parallax_factor
