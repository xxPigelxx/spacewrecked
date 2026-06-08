extends Node2D
class_name MalfunctionSpawner

## Haelt die Stoerungs-Interactables als Kinder (feste Reihenfolge = Kind-Reihenfolge).
## GameState steuert ueber die Kurve, wie viele JETZT aktiv sein sollen;
## der Spawner aktiviert die naechsten ungenutzten Kinder bis zu diesem Ziel.
## Mehrere koennen gleichzeitig aktiv sein - der Spieler waehlt, welche er repariert.

## Kurve: x = Fortschritt 0..1, y = wie viele Stoerungen JETZT aktiv sein sollen.
@export var active_curve: Curve

var _children: Array[Node] = []
var _next_index := 0
var _target := 0
var _in_progress: Node = null

func _ready() -> void:
	GameState.register_spawner(self)
	for c in get_children():
		_children.append(c)
		if c.has_method("deactivate"):
			c.deactivate()

func begin() -> void:
	_next_index = 0
	_target = 0
	_in_progress = null
	for c in _children:
		if c.has_method("deactivate"):
			c.deactivate()

func update_for_progress(progress: float) -> void:
	var target := 1
	if active_curve:
		target = int(round(active_curve.sample(progress)))
	_target = max(0, target)
	while active_unsolved_count() < _target and _next_index < _children.size():
		var c: Node = _children[_next_index]
		_next_index += 1
		if c.has_method("activate"):
			c.activate()

func active_unsolved_count() -> int:
	var n := 0
	for c in _children:
		if c.has_method("is_active_unsolved") and c.is_active_unsolved():
			n += 1
	return n

func clear_all() -> void:
	_in_progress = null
	for c in _children:
		if c.has_method("deactivate"):
			c.deactivate()

func set_in_progress(child: Node) -> void:
	_in_progress = child

func resolve_in_progress() -> void:
	if _in_progress and _in_progress.has_method("mark_solved"):
		_in_progress.mark_solved()
	_in_progress = null
