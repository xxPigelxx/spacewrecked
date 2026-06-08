extends Area2D

@onready var texture_progress_bar: TextureProgressBar = $TextureProgressBar
var planet_detected:= false
var progress := 0

func _physics_process(delta: float) -> void:
	if planet_detected:
		progress += 1
	else:
		progress = 0
	texture_progress_bar.value = progress


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Planet"):
		planet_detected = true
		


func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group("Planet"):
		planet_detected = false
