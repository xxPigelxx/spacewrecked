extends CanvasModulate

## Verdunkelt den Bildschirm, wenn das Stromsystem ausgefallen ist.
## sichtbar (= dunkel) wenn Strom kaputt, unsichtbar (= hell) wenn Strom OK.

func _ready() -> void:
	GameState.broken_systems_changed.connect(_update)
	_update()

func _update() -> void:
	visible = GameState.is_system_broken("strom")
