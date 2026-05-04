extends Area2D

enum Side {
	LEFT,
	RIGHT
}

@export var socket_color: Color = Color.WHITE
@export var pair_id: String = ""
@export var side: = Side.LEFT

var occupied := false
var cleared := false

@onready var visual = $Sprite2D


func _ready() -> void:
	add_to_group("socket")
	
	if visual:
		visual.modulate = socket_color
