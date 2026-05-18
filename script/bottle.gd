extends Draggable

@export var bottle_color: Color = Color.WHITE
@export var amount: float = 100.0
@export var pour_rate: float = 20.0
@export var bottle_name: = "Bottle"
@export var bottle_texture: Texture2D = preload("uid://chm0cx66fx8kh")

@onready var cpu_particles_2d: CPUParticles2D = $Bottle/CPUParticles2D
@onready var rich_text_label: RichTextLabel = $RichTextLabel
@onready var bottle_sprite: Sprite2D = $Bottle


var current_container: Node = null
var is_pouring := false
var rotate_tween: Tween = null


func _set_up():
	bottle_sprite.texture = bottle_texture
	bottle_sprite.modulate = bottle_color
	
	rich_text_label.text = bottle_name
	rich_text_label.visible = false
	
func _while_dragging(delta: float) -> void:
	current_container = null

	for a in area.get_overlapping_areas():
		if a.is_in_group("Container"):
			current_container = a.get_parent()
			break

	if current_container and amount > 0.0 and not current_container.is_full():
		if not is_pouring:
			start_pouring()

		var poured = min(pour_rate * delta, amount)
		amount -= poured
		current_container.add_to_container(self, poured)
	else:
		if is_pouring:
			stop_pouring()

func _on_drag_ended() -> void:
	stop_pouring()

func start_pouring() -> void:
	is_pouring = true
	if position.x >= get_window().size.x /2:
		rotate_to(deg_to_rad(-120))
	else:
		rotate_to(deg_to_rad(120))
	cpu_particles_2d.modulate = bottle_color
	cpu_particles_2d.emitting = true

func stop_pouring() -> void:
	is_pouring = false
	current_container = null
	rotate_to(0.0)
	cpu_particles_2d.emitting = false

func _on_mouse_enterd():
	rich_text_label.visible = true

func _on_mouse_exited():
	rich_text_label.visible = false
	
func rotate_to(target_rotation: float) -> void:
	if rotate_tween:
		rotate_tween.kill()

	rotate_tween = create_tween()
	rotate_tween.tween_property(bottle_sprite, "rotation", target_rotation, 1)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
