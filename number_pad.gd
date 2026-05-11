extends Node2D

@onready var numpad_text: RichTextLabel = $PanelContainer/ProcreateAtlas/NumpadText
@onready var numpad_buttons: Node = $PanelContainer/MarginContainer/GridContainer

@export var max_length := 6
@export var code := "123456"
@export var shake_amount := 25.0
@export var shake_speed := 0.05

@export var door: Node = null

var _text_start_position: Vector2

func _ready() -> void:
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
		if numpad_text.text != code:
			_shake_text()
		return

	numpad_text.text += button.text
	
	if numpad_text.text.length() >= max_length:
		_try_submit()

func _try_submit() -> void:
	if numpad_text.text == code:
		if door:
			door.locked = true
		print("Puzzle Solved")
	else:
		_shake_text()

func _shake_text() -> void:
	numpad_text.position = _text_start_position
	
	var tween := create_tween()
	tween.tween_property(numpad_text, "position", _text_start_position + Vector2(-shake_amount, 0), shake_speed)
	tween.tween_property(numpad_text, "position", _text_start_position + Vector2(shake_amount, 0), shake_speed)
	tween.tween_property(numpad_text, "position", _text_start_position + Vector2(-shake_amount * 0.7, 0), shake_speed)
	tween.tween_property(numpad_text, "position", _text_start_position + Vector2(shake_amount * 0.7, 0), shake_speed)
	tween.tween_property(numpad_text, "position", _text_start_position, shake_speed)
