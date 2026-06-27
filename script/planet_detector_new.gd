extends Area2D

## Fester Detektor in der Bildschirmmitte. Füllt die Fortschrittsanzeige,
## solange ein Planet überlappt. Ist die Anzeige voll, wird planet_scanned
## mit der planet_id gemeldet — genau einmal pro Aufenthalt.

signal planet_scanned(planet_id: String)

@export var scan_time := 1.5  ## Sekunden bis ein Scan fertig ist
@onready var texture_progress_bar: TextureProgressBar = $TextureProgressBar
@onready var planet_name_label: DyslexiaLabel = $PlanetNameLabel

var _current_planet: Area2D = null
var _progress := 0.0
var _scanned_current := false

func _ready() -> void:
	texture_progress_bar.min_value = 0.0
	texture_progress_bar.max_value = 100.0
	planet_name_label.visible = false

func _physics_process(delta: float) -> void:
	if _current_planet and not _scanned_current:
		_progress += (100.0 / scan_time) * delta
		if _progress >= 100.0:
			_progress = 100.0
			_scanned_current = true
			var id: String = _current_planet.planet_id if "planet_id" in _current_planet else _current_planet.name
			planet_scanned.emit(id)
	elif _current_planet == null:
		_progress = 0.0
	texture_progress_bar.value = _progress

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Planet"):
		planet_name_label.visible = true
		planet_name_label.text = area.name
		_current_planet = area
		_scanned_current = false
		_progress = 0.0

func _on_area_exited(area: Area2D) -> void:
	if area == _current_planet:
		planet_name_label.visible = false
		planet_name_label.text = ""
		_current_planet = null
		_scanned_current = false
		_progress = 0.0
