extends Node2D

## Abschluss-Animation nach dem Messfenster. GameState.died_early entscheidet,
## welche der beiden Animationen laeuft; danach geht es zum End-Fragebogen.
##
## Der Ablauf selbst steckt komplett im AnimationPlayer. Hier steht nur, was
## nicht in die Timeline gehoert: die Auswahl, der ziehende Sternenhintergrund,
## die Triebwerksflammen und der Szenenwechsel.

const POST_FLOW := "res://Scenes/Menu/post_flow.tscn"

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var space_bg: Node2D = $SpaceBg
@onready var ship: Sprite2D = $SmallShip
func _ready() -> void:
	space_bg.play_space_bg()
	_start_engine_flames()

	anim.play("BadEnding" if GameState.died_early else "ReturnHome")
	await anim.animation_finished

	SceneSwitcher.switch_scene(POST_FLOW)

## Die drei FierSFX unter dem Schiff brennen durchgehend. Die Asteroiden
## starten ihre eigenen Flammen selbst in astroid.gd.
func _start_engine_flames() -> void:
	for flame in ship.get_children():
		flame.play("Fier_ainmation")
