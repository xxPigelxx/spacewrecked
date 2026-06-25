extends Node2D

@export var error_code := "1234"
@export var lamp_flash_time := 0.5

@onready var dyslexia_label: DyslexiaLabel = $DyslexiaLabel
@onready var lamp: Sprite2D = $lamp
@onready var lamp_2: Sprite2D = $lamp2

var current_time := 0.0
var lamp_active := true

func _ready() -> void:
	dyslexia_label.text = error_code
	_update_lamps()

func _process(delta: float) -> void:
	current_time += delta

	if current_time >= lamp_flash_time:
		lamp_active = !lamp_active
		_update_lamps()
		current_time = 0.0

func _update_lamps() -> void:
	lamp.set_active(lamp_active)
	lamp_2.set_active(lamp_active)
