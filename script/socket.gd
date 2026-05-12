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
@onready var animated_sprite_2d: AnimatedSprite2D = $Sprite2D/lamp/AnimatedSprite2D
@onready var path_follow_2d: PathFollow2D = $Path2D/PathFollow2D


var occupied := false:
	set(value):
		occupied = value
		_update_visual()

var aktive := false:
	set(value):
		aktive = value
		_update_visual()
		
@onready var visual = $Sprite2D


func _ready() -> void:
	add_to_group("socket")
	
	if side == Side.Right:
		lamp.position.x = 200
	lamp.active_color = socket_color
	_update_visual()


func _update_visual():
	if !visual:
		return
		
	if !occupied:
		visual.self_modulate = socket_color * 0.6
	else:
		visual.self_modulate = socket_color
	lamp.set_active(aktive)
