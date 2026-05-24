extends CharacterBody2D

@export var speed := 300.0

@onready var player_light: PointLight2D = $playerLight
@onready var flashlights: PointLight2D = $Flashlights

var ship_lights_on := false
var has_manual := false

func _ready() -> void:
	ship_lights_on = GameState.ship_lights
	has_manual = GameState.manule_aquiered

	switch_lights(ship_lights_on)

	GameState.manual_acquired_changed.connect(_on_manual_changed)
	GameState.ship_lights_changed.connect(switch_lights)

func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO

	if Input.is_action_pressed("pause"):
		SceneSwitcher.open_overlay_scene("res://Scenes/Menu/PauseMenu.tscn")

	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	if Input.is_action_pressed("move_up"):
		direction.y -= 1

	direction = direction.normalized()
	velocity = direction * speed
	move_and_slide()

	if Input.is_action_just_pressed("flash_light"):
		toggle_flashlight()

	if flashlights.visible:
		flashlights.look_at(get_global_mouse_position())

func switch_lights(val: bool) -> void:
	ship_lights_on = val
	player_light.visible = not ship_lights_on

	if ship_lights_on:
		flashlights.visible = false

func toggle_flashlight() -> void:
	if not has_manual:
		return

	if ship_lights_on:
		return

	flashlights.visible = !flashlights.visible

func _on_manual_changed(acquired: bool) -> void:
	has_manual = acquired

	if not has_manual:
		flashlights.visible = false
