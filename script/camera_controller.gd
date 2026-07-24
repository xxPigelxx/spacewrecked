extends Camera2D

# === SETTINGS ===
@export var move_time: float = 0.4   # how long the transition takes
@export var edge_size: int = 20      # distance from screen edge to trigger movement

# Optional limits (set these in the inspector)
@export var min_grid: Vector2i = Vector2i(-1000, -1000)
@export var max_grid: Vector2i = Vector2i(1000, 1000)

# === INTERNAL ===
var grid_pos: Vector2i = Vector2i(0, 0)
var moving: bool = false
func _process(delta):
	# Die Kamera liest WASD direkt, nicht ueber den Spieler. Bei offenem Overlay
	# muss sie deshalb selbst stillhalten — sonst scrollt sie waehrend eines
	# Raetsels vom Spieler weg und steht nach dem Schliessen woanders.
	if moving or SceneSwitcher.is_overlay_open:
		return

	if Input.is_action_just_pressed("move_right"):
		move_right()

	elif Input.is_action_just_pressed("move_left"):
		move_left()

	elif Input.is_action_just_pressed("move_down"):
		move_down()

	elif Input.is_action_just_pressed("move_up"):
		move_up()


func move(dir: Vector2i):
	if moving:
		return

	var new_grid = grid_pos + dir

	# Clamp to limits
	new_grid.x = clamp(new_grid.x, min_grid.x, max_grid.x)
	new_grid.y = clamp(new_grid.y, min_grid.y, max_grid.y)

	# If no movement, stop
	if new_grid == grid_pos:
		return

	grid_pos = new_grid
	moving = true
	$ColorRect.visible = true
	var screen_size = get_viewport_rect().size
	var target_position = Vector2(grid_pos) * screen_size

	var tween = create_tween()
	tween.tween_property(self, "position", target_position, move_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	tween.finished.connect(_on_tween_finished)
	
func move_left():
	move(Vector2i(-1, 0))
func move_right():
	move(Vector2i(1, 0))
func move_up():
	move(Vector2i(0, -1))
func move_down():
	move(Vector2i(0, 1))
func _on_button_left_pressed():
	move_left()
func _on_button_right_pressed():
	move_right()
func _on_button_up_pressed():
	move_up()
func _on_button_down_pressed():
	move_down()
func _on_tween_finished():
	moving = false
	$ColorRect.visible = false
