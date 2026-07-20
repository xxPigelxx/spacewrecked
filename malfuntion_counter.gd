extends Control

## Kleiner HUD-Counter (aktives Feedback ausserhalb des Handbuchs):
##   Solved       = Anzahl bereits reparierter Stoerungen (Score, zaehlt hoch)
##   Malfunctions = Anzahl aktuell offener Stoerungen (steigt/faellt live)
##
## Feedback-Animationen — jedes Icon reagiert auf SEINEN Wert:
##   offene Stoerung steigt -> Warn-Icon wackelt (Rotation-Shake)
##   Reparatur (solved steigt) -> Solved-Icon ploppt auf (Bounce-Scale)
## Rotation/Scale statt Position, weil die Icons in HBox-Containern liegen, die
## deren Position verwalten (Position-Tweens waeren dort unzuverlaessig).
##
## Nur waehrend der JOURNEY sichtbar: die Kategorie-Zaehler in GameState werden
## nur dort gefuellt (Tutorial-Stoerungen im SETUP zaehlen hier nicht mit).

@onready var _solved_lbl: Label = $MarginContainer/Vbox/SolvedIcon/Solved
@onready var _open_lbl: Label = $MarginContainer/Vbox/Malfunction/Malfunctions
@onready var _solved_icon: Control = $MarginContainer/Vbox/SolvedIcon/TextureRect
@onready var _open_icon: Control =$MarginContainer/Vbox/Malfunction/TextureRect

var _prev_open := 0
var _prev_solved := 0
var _shake_tween: Tween
var _bounce_tween: Tween

func _ready() -> void:
	GameState.broken_systems_changed.connect(refresh)
	GameState.malfunctions_solved_changed.connect(func(_c): refresh())
	GameState.phase_changed.connect(func(_p): refresh())
	refresh()

## Summe der offenen Stoerungen ueber alle vier Systeme.
func _open_count() -> int:
	return GameState.broken_strom + GameState.broken_treibstoff \
		+ GameState.broken_schild + GameState.broken_navigation

func refresh() -> void:
	var in_journey: bool = ("phase" in GameState) and GameState.phase == GameState.Phase.JOURNEY
	visible = in_journey
	if not in_journey:
		return
	var solved: int = GameState.malfunctions_solved
	var open: int = _open_count()
	_solved_lbl.text = str(solved)
	_open_lbl.text = str(open)

	if open > _prev_open:
		_play_shake(_open_icon)
	if solved > _prev_solved:
		_play_bounce(_solved_icon)
	_prev_open = open
	_prev_solved = solved

## Kurzes Wackeln eines Icons (Rotation) bei einer neuen Stoerung.
func _play_shake(icon: Control) -> void:
	if _shake_tween and _shake_tween.is_running():
		_shake_tween.kill()
	icon.pivot_offset = icon.size * 0.5
	icon.rotation = 0.0
	_shake_tween = create_tween()
	_shake_tween.tween_property(icon, "rotation", deg_to_rad(24), 0.04)
	_shake_tween.tween_property(icon, "rotation", deg_to_rad(-20), 0.04)
	_shake_tween.tween_property(icon, "rotation", deg_to_rad(12), 0.04)
	_shake_tween.tween_property(icon, "rotation", 0.0, 0.05)

## Kurzes Aufploppen eines Icons (Scale) bei einer Reparatur.
func _play_bounce(icon: Control) -> void:
	if _bounce_tween and _bounce_tween.is_running():
		_bounce_tween.kill()
	icon.pivot_offset = icon.size * 0.5
	icon.scale = Vector2.ONE
	_bounce_tween = create_tween()
	_bounce_tween.tween_property(icon, "scale", Vector2(1.6, 1.6), 0.12) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_bounce_tween.tween_property(icon, "scale", Vector2.ONE, 0.35) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
