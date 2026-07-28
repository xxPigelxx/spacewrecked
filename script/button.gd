extends Button
@export var hover_scale: Vector2 = Vector2(1.1,1.1)
@export var pressed_scale: Vector2 = Vector2(0.9,0.9)

var original_scale

func _ready() -> void:
	mouse_entered.connect(_button_enter)
	mouse_exited.connect(_button_exit)
	pressed.connect(_button_pressed)
	original_scale = scale
	call_deferred("_init_pivot")
	
func _init_pivot() -> void:
	pivot_offset_ratio = Vector2(0.5,0.5)
	
func _button_enter() -> void:
	if !disabled:
		create_tween().tween_property(self, "scale", hover_scale, 0.1).set_trans(Tween.TRANS_SINE)
		AudioManager.play_sfx("res://resources/assets/sfx/Interface_Bleeps_Wav/Bleep_07.wav")
func _button_exit() -> void:
	create_tween().tween_property(self, "scale", original_scale, 0.1).set_trans(Tween.TRANS_SINE)
func _button_pressed() -> void:
	var button_press_tween: Tween = create_tween()
	button_press_tween.tween_property(self, "scale", pressed_scale, 0.06).set_trans(Tween.TRANS_SINE)
	button_press_tween.tween_property(self, "scale", hover_scale, 0.12).set_trans(Tween.TRANS_SINE)
	AudioManager.play_sfx("res://resources/assets/sfx/Interface_Bleeps_Wav/Data_Point_02.wav")
	
