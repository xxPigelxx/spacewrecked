extends Node2D

@onready var container_sprite: Sprite2D = $Container/ContainerSprite
@onready var color_rect: ColorRect = $Container/ColorRect
@onready var liquid_line: AnimatedSprite2D =$Container/ColorRect/LiquidLine

@export var max_fill: float = 140.0
var current_fill: float = 0.0

var bottles: Array = []
var mixed_color: Color = Color(0, 0, 0, 1)

var full_liquid_height: float
var bottom_y: float

func _ready() -> void:
	full_liquid_height = color_rect.size.y
	bottom_y = color_rect.position.y + color_rect.size.y
	update_visual()

func add_to_container(bottle, amount: float) -> void:
	if not bottle.is_in_group("Bottle"):
		return
	
	if bottle not in bottles:
		bottles.append(bottle)
	
	current_fill = min(current_fill + amount, max_fill)
	update_mixed_color(bottle.bottle_color, amount)
	update_visual()

func update_mixed_color(new_color: Color, amount: float) -> void:
	if current_fill <= 0.0:
		mixed_color = new_color
		return
	
	var mix_strength := amount / current_fill
	mixed_color = mixed_color.lerp(new_color, mix_strength)

func update_visual() -> void:
	var percent := current_fill / max_fill
	var new_height := full_liquid_height * percent
	
	color_rect.size.y = new_height
	color_rect.position.y = bottom_y - new_height
	color_rect.color = mixed_color
	liquid_line.modulate = mixed_color
	if percent >= 0.01:
		liquid_line.visible = true
		liquid_line.play()
	else:
		liquid_line.visible = false
		liquid_line.stop()
func reset_container() -> void:
	bottles.clear()
	current_fill = 0.0
	mixed_color = Color(0, 0, 0, 1)
	update_visual()

func is_full() -> bool:
	return current_fill >= max_fill

func _check_win() -> bool:
	return is_full()


func _on_return_bt_pressed() -> void:
	SceneSwitcher.close_overlay_scene()


func _on_reset_bt_pressed() -> void:
	reset_container()
