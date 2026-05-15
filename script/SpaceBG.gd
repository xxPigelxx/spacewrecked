extends Node2D


func play_space_bg():
	for child in get_children():
		if child is AnimatedSprite2D:
			child.play()

func stop_space_bg():
	for child in get_children():
		if child is AnimatedSprite2D:
			child.stop()
