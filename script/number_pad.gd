extends Node

@onready var numpad_text: RichTextLabel = $PanelContainer/ProcreateAtlas/NumpadText
@onready var numpad_buttons: Node = $PanelContainer/MarginContainer/GridContainer
@onready var lamp: Sprite2D = $PanelContainer/ProcreateAtlas/lamp
@onready var lamp_2: Sprite2D = $PanelContainer/ProcreateAtlas/lamp2

@export var max_length := 6
@export var code := "123456"
@export var shake_amount := 25.0
@export var shake_speed := 0.05

@export var door_id:= "keypad1"
@onready var manual: CanvasLayer = $Manual

var _text_start_position: Vector2
var cheat_on := false
var cheat_code := "666666"
var lamp_scale
var solved := false

func _ready() -> void:
	solved = false
	lamp_scale = lamp.scale
	_text_start_position = numpad_text.position
	for child in numpad_buttons.get_children():
		if child is Button:
			child.pressed.connect(_on_button_pressed.bind(child))

func _on_button_pressed(button: Button) -> void:
	var value := button.text.strip_edges().to_lower()

	if value == "back":
		if numpad_text.text.length() > 0:
			numpad_text.text = numpad_text.text.left(numpad_text.text.length() - 1)
		return

	if value == "enter":
		_try_submit()
		return

	if numpad_text.text.length() >= max_length:
		_try_submit()
		return

	numpad_text.text += button.text
	
	if numpad_text.text.length() >= max_length:
		_try_submit()

func _try_submit() -> void:
	if solved:
		return
	if numpad_text.text == code  or (numpad_text.text == cheat_code and cheat_on):
		solved = true
		_on_win()
		AudioManager.play_success()
	else:
		_shake_text()
		AudioManager.play_sfx("res://resources/assets/sfx/Interface_Bleeps_Wav/Denied_03.wav")

func _shake_text() -> void:
	numpad_text.position = _text_start_position
	
	var tween := create_tween()
	tween.tween_property(numpad_text, "position", _text_start_position + Vector2(-shake_amount, 0), shake_speed)
	tween.tween_property(numpad_text, "position", _text_start_position + Vector2(shake_amount, 0), shake_speed)
	tween.tween_property(numpad_text, "position", _text_start_position + Vector2(-shake_amount * 0.7, 0), shake_speed)
	tween.tween_property(numpad_text, "position", _text_start_position + Vector2(shake_amount * 0.7, 0), shake_speed)
	tween.tween_property(numpad_text, "position", _text_start_position, shake_speed)


func _flash_lights() -> Tween:
	var tween := create_tween()

	for i in range(2):
		tween.tween_property(lamp, "scale", lamp_scale*1.2, 0.05)
		tween.tween_property(lamp_2, "scale", lamp_scale*1.2, 0.05)
		
		tween.tween_property(lamp, "scale", lamp_scale, 0.05)
		tween.tween_property(lamp_2, "scale", lamp_scale, 0.05)
		

	return tween

func _on_return_bt_pressed() -> void:
	SceneSwitcher.close_overlay_scene(true, false)

func _on_win() -> void:
	lamp.set_active(true)
	lamp_2.set_active(true)
	await _flash_lights().finished
	GameState.unlock_door(door_id)
	SceneSwitcher.close_overlay_scene(true,false)
