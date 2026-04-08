extends Sprite2D
@onready var vertical: VSlider = $"../Vertical"
@onready var horisontal: VSlider = $"../Horisontal"

var _image_size_x: int = 4200	
var _image_size_y: int = 3300

func _ready() -> void:
	vertical.max_value = _image_size_y 
	horisontal.max_value = _image_size_x 




func _on_vertical_value_changed(value: float) -> void:
	position.y = value


func _on_horisontal_value_changed(value: float) -> void:
	position.x = value
