extends Area2D
class_name Socket
enum Side{
	Left,
	Right
}
	
@export var side := Side.Left
@export var socket_color: Color = Color.WHITE
@export var pair_id: String = ""

@onready var lamp: Sprite2D = $Sprite2D/lamp


var occupied := false
var aktive := false:
	set(value):
		aktive = value
		_update_visual()
		
@onready var visual = $Sprite2D


func _ready() -> void:
	add_to_group("socket")
	
	if side == Side.Right:
		lamp.position.x = 200
	
	_update_visual()

func _update_visual():
	if !visual:
		return
		
	if !aktive:
		visual.modulate = socket_color * 0.4
	else:
		visual.modulate = socket_color
