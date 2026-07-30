extends Draggable

@export var bottle_color: Color = Color.WHITE
@export var pour_rate: float = 15.0
@export var bottle_name: = "Bottle"
@export var bottle_texture: Texture2D = preload("uid://chm0cx66fx8kh")
@export var pour_rotation: = -120 

@onready var cpu_particles_2d: CPUParticles2D = $Bottle/CPUParticles2D
@onready var rich_text_label: DyslexiaLabel = $RichTextLabel
@onready var bottle_sprite: Sprite2D = $Bottle


var current_container: Node = null
var is_pouring := false
var is_draining := false
var rotate_tween: Tween = null


func _set_up():
	bottle_sprite.texture = bottle_texture
	bottle_sprite.modulate = bottle_color
	
	# Ueber set_source_text, nicht .text — sonst kennt das DyslexiaLabel weiter
	# nur seinen Szenen-Text und setzt den Namen beim naechsten Render zurueck.
	rich_text_label.set_source_text(bottle_name)
	rich_text_label.visible = false
	
func _while_dragging(delta: float) -> void:
	current_container = null

	for a in area.get_overlapping_areas():
		if a.is_in_group("Container"):
			current_container = a.get_parent()
			break

	var wants_pour := Input.is_action_pressed("pour")
	var wants_drain := Input.is_action_pressed("drain")

	# Ablassen hat Vorrang, damit gleichzeitiges Druecken nicht flackert.
	if current_container and wants_drain and current_container.has_liquid_from(self):
		stop_pouring()
		if not is_draining:
			start_draining()

		current_container.remove_from_container(self, pour_rate * delta)

	elif current_container and not current_container.is_full() and wants_pour:
		stop_draining()
		if not is_pouring:
			start_pouring()

		var poured = pour_rate * delta
		current_container.add_to_container(self, poured)

	else:
		stop_pouring()
		stop_draining()

func _on_drag_ended() -> void:
	stop_pouring()
	stop_draining()
	current_container = null

func start_pouring() -> void:
	is_pouring = true
	#if position.x >= get_window().size.x / 2.0:
		#rotate_to(deg_to_rad(-120))
	#else:
		#rotate_to(deg_to_rad(120))
	rotate_to(deg_to_rad(pour_rotation))
	cpu_particles_2d.modulate = bottle_color
	cpu_particles_2d.emitting = true

func stop_pouring() -> void:
	if not is_pouring:
		return
	is_pouring = false
	rotate_to(0.0)
	cpu_particles_2d.emitting = false

## Ablassen: Flasche kippt in die Gegenrichtung, keine Partikel, weil
## nichts herauslaeuft.
func start_draining() -> void:
	is_draining = true
	rotate_to(deg_to_rad(-pour_rotation))
	cpu_particles_2d.emitting = false

func stop_draining() -> void:
	if not is_draining:
		return
	is_draining = false
	rotate_to(0.0)

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
