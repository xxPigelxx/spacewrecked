extends Sprite2D

@onready var parent: Node2D = $".."

var pressing := false

@export var maxLength := 50.0
@export var deadzone := 5.0

func _ready() -> void:
	maxLength *= parent.scale.x

func _process(delta: float) -> void:
	if pressing:
		if get_global_mouse_position().distance_to(parent.global_position) <= maxLength:
			global_position = get_global_mouse_position()
		else:
			var angle = parent.global_position.angle_to_point(get_global_mouse_position())
			global_position.x = parent.global_position.x + cos(angle)*maxLength
			global_position.y = parent.global_position.y + sin(angle)*maxLength
		calculateVector()
	else:
		global_position = lerp(global_position, parent.global_position, delta*10)
		parent.posVector = Vector2.ZERO
	
func calculateVector():
	var offset = global_position - parent.global_position

	if offset.length() < deadzone:
		parent.posVector = Vector2.ZERO
	else:
		parent.posVector = offset / maxLength
		parent.posVector = parent.posVector.clamp(Vector2(-1, -1), Vector2(1, 1))
func _on_button_button_down() -> void:
	pressing = true


func _on_button_button_up() -> void:
	pressing = false
