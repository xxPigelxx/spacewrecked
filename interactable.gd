extends Node2D

@export var scene: PackedScene = preload("res://Scenes/Puzzle/cockpit_window.tscn")

@onready var label: RichTextLabel = $Area2D/CollisionShape2D/Label

var player_near := false

func _ready() -> void:
	label.bbcode_enabled = true
	label.text = ""
	label.visible = false

func _input(event: InputEvent) -> void:
	if player_near and event.is_action_pressed("interact"):
		get_tree().change_scene_to_packed(scene)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Enterd")
		player_near = true
		label.visible = true
		label.text = "[wave amp=20 freq=4]Press E to interact[/wave]"

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near = false
		label.visible = false
		label.text = ""
