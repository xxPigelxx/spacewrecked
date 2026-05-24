extends Label

func _process(delta: float) -> void:
	var fps := 1.0 / delta
	print(fps)
	text = "FPS: %d" % fps
