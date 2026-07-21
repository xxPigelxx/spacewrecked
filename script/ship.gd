extends Node2D
@onready var fier_sfx_1: AnimatedSprite2D = $FierSFX3
@onready var fier_sfx_2: AnimatedSprite2D = $FierSFX4
@onready var space_bg: Node2D = $SpaceBg
@onready var shilds: Sprite2D = $shilds

@export var ship_impact_shake_intecity:= 5

## Fliegt das Schiff gerade? Nur bei Wechsel wird umgeschaltet, damit die
## Animationen nicht jeden Frame neu angestossen werden.
var _flying := false
## Schild sichtbar? Haengt an der Schild-Stoerung — steht die Frequenz wieder
## richtig, meldet das Schild-Raetsel mark_solved() und der Schirm geht an.
var _shields_up := false

func _ready() -> void:
	fier_sfx_1.visible = false
	fier_sfx_2.visible = false
	space_bg.visible = false
	shilds.visible = false

func _physics_process(_delta: float) -> void:
	var should_fly := _is_journey() and _has_fuel()
	if should_fly != _flying:
		_flying = should_fly
		if should_fly:
			start_flight()
		else:
			stop_flight()

	var shields_up := not GameState.is_system_broken("schild")
	if shields_up != _shields_up:
		_shields_up = shields_up
		shilds.visible = shields_up


func shake_ship():
	var tween = create_tween()
	var intensity = deg_to_rad(ship_impact_shake_intecity)

	for i in range(4):
		tween.tween_property(self, "rotation", intensity, 0.04)
		tween.tween_property(self, "rotation", -intensity, 0.04)
		intensity *= 0.6

	tween.tween_property(self, "rotation", 0.0, 0.05)

func _play_fier_animation():
	fier_sfx_1.visible = true
	fier_sfx_2.visible = true
	fier_sfx_1.play("Fier_ainmation")
	fier_sfx_2.play("Fier_ainmation")

func _play_space_animation():
	space_bg.visible = true
	space_bg.play_space_bg()

func _stop_fier_animation():
	fier_sfx_1.stop()
	fier_sfx_2.stop()
	fier_sfx_1.visible = false
	fier_sfx_2.visible = false

func _stop_space_animation():
	space_bg.stop_space_bg()
	space_bg.visible = false

func start_flight():
	_play_fier_animation()
	_play_space_animation()

## Ohne Treibstoff treibt das Schiff: keine Flammen, kein ziehender Hintergrund.
func stop_flight():
	_stop_fier_animation()
	_stop_space_animation()

func _is_journey() -> bool:
	return ("phase" in GameState) and GameState.phase == GameState.Phase.JOURNEY

func _has_fuel() -> bool:
	return not GameState.is_system_broken("treibstoff")
