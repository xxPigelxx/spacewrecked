extends CanvasLayer

@onready var container_sprite: Sprite2D = $Container/ContainerSprite
@onready var color_rect: ColorRect = $Container/ColorRect
@onready var liquid_line: AnimatedSprite2D = $Container/ColorRect/LiquidLine
@onready var fulestand: DyslexiaLabel = $Fulestand
@onready var error_code: Node2D = $ErrorCode

## Fassungsvermoegen des Behaelters in ml. Nur die Obergrenze — die Rezepte
## liegen bewusst darunter, der Behaelter muss nicht voll werden.
@export var max_fill: float = 150.0
@export var recipe: Array[Dictionary] = [{"bottle_name":"Wasser","target_ml":20.0},{"bottle_name":"Xytherium","target_ml":12.0},{"bottle_name":"Hyperion","target_ml":23.0},{"bottle_name":"Vortex","target_ml":25.0} ]

## Spielraum in ml (±). 10 = ±10 ml um den Zielwert.
@export_range(1.0, 30.0, 0.5, "suffix:ml") var leeway: float = 10.0

## Muss der Behälter komplett voll sein oder reicht die richtige Mischung?
## Greift nur, wenn kein Rezept gesetzt ist.
@export var require_full: bool = true

@export var category: String = "treibstoff"

var malfunction = null
var current_fill: float = 0.0
var bottles: Array = []
var mixed_color: Color = Color(0, 0, 0, 1)
var completed: = false
## Wie viel wurde von jeder Flasche (per bottle_name) eingefüllt
var poured_per_bottle: Dictionary = {}

var full_liquid_height: float
var bottom_y: float

## Farbe je bottle_name, damit die Mischfarbe nach dem Ablassen neu
## berechnet werden kann.
var _bottle_colors: Dictionary = {}

func _ready() -> void:
	full_liquid_height = color_rect.size.y
	bottom_y = color_rect.position.y + color_rect.size.y
	call_deferred("update_visual")
	call_deferred("_update_fill_label")

func add_to_container(bottle, amount: float) -> void:
	if not bottle.is_in_group("Bottle"):
		return

	if bottle not in bottles:
		bottles.append(bottle)

	current_fill = min(current_fill + amount, max_fill)

	# Wie viel wurde von dieser Flasche eingefüllt verfolgen
	var bname: String = bottle.bottle_name
	poured_per_bottle[bname] = poured_per_bottle.get(bname, 0.0) + amount
	_bottle_colors[bname] = bottle.bottle_color

	update_mixed_color()
	update_visual()
	if _check_win():
		_on_win()

## Laesst Fluessigkeit einer Flasche wieder ab, solange davon etwas im
## Behaelter ist. Gibt zurueck wie viel tatsaechlich entfernt wurde.
func remove_from_container(bottle, amount: float) -> float:
	if not bottle.is_in_group("Bottle"):
		return 0.0

	var bname: String = bottle.bottle_name
	var already_in: float = poured_per_bottle.get(bname, 0.0)
	if already_in <= 0.0:
		return 0.0

	var removed: float = min(amount, already_in)
	poured_per_bottle[bname] = already_in - removed

	if poured_per_bottle[bname] <= 0.0:
		poured_per_bottle.erase(bname)
		bottles.erase(bottle)

	current_fill = max(current_fill - removed, 0.0)

	update_mixed_color()
	update_visual()
	if _check_win():
		_on_win()
	return removed

## Ist von dieser Flasche ueberhaupt etwas im Behaelter?
func has_liquid_from(bottle) -> bool:
	return poured_per_bottle.get(bottle.bottle_name, 0.0) > 0.0

## Mischfarbe als gewichteter Durchschnitt aller eingefuellten Mengen.
## Wird komplett neu berechnet, damit Ablassen die Farbe korrekt zuruecknimmt.
func update_mixed_color() -> void:
	var total := 0.0
	for amount in poured_per_bottle.values():
		total += amount

	if total <= 0.0:
		mixed_color = Color(0, 0, 0, 1)
		return

	var r := 0.0
	var g := 0.0
	var b := 0.0
	for bname in poured_per_bottle:
		var weight: float = poured_per_bottle[bname] / total
		var col: Color = _bottle_colors.get(bname, Color.WHITE)
		r += col.r * weight
		g += col.g * weight
		b += col.b * weight

	mixed_color = Color(r, g, b, 1)

func update_visual() -> void:
	var percent := current_fill / max_fill
	var new_height := full_liquid_height * percent

	color_rect.set_deferred("size", Vector2(color_rect.size.x, new_height))
	color_rect.set_deferred("position", Vector2(color_rect.position.x, bottom_y - new_height))
	color_rect.color = mixed_color
	liquid_line.modulate = mixed_color
	if percent >= 0.01:
		liquid_line.visible = true
		liquid_line.play()
	else:
		liquid_line.visible = false
		liquid_line.stop()
	_update_fill_label()
		
func reset_container() -> void:
	bottles.clear()
	current_fill = 0.0
	mixed_color = Color(0, 0, 0, 1)
	poured_per_bottle.clear()
	_bottle_colors.clear()
	update_visual()

func is_full() -> bool:
	return current_fill >= max_fill

## Gibt für jeden Rezept-Eintrag zurück wie weit er vom Ziel entfernt ist (in ml,
## 0.0 = perfekt). Gibt ein leeres Array zurück wenn kein Rezept definiert ist.
func get_recipe_deltas() -> Array[float]:
	if recipe.is_empty():
		return []
	var deltas: Array[float] = []
	for entry in recipe:
		var bname: String = entry.get("bottle_name", "")
		var target_ml: float = entry.get("target_ml", 0.0)
		var actual_ml: float = poured_per_bottle.get(bname, 0.0)
		deltas.append(abs(actual_ml - target_ml))
	return deltas

func _check_win() -> bool:
	if recipe.is_empty():
		return is_full()
	if current_fill <= 0.0:
		return false
	# Jede Zutat wird in absoluten ml geprueft — der Behaelter muss dafuer
	# nicht voll sein, es zaehlt nur die eingefuellte Menge je Flasche.
	var targets := {}
	for entry in recipe:
		targets[entry.get("bottle_name", "")] = entry.get("target_ml", 0.0)

	# Flaschen, die nicht im Rezept stehen, haben Ziel 0 ml — so faellt auch
	# eine falsche Zutat auf, statt einfach ignoriert zu werden.
	for bname in poured_per_bottle:
		if not targets.has(bname):
			targets[bname] = 0.0

	for bname in targets:
		var target_ml: float = targets[bname]
		var actual_ml: float = poured_per_bottle.get(bname, 0.0)
		if abs(actual_ml - target_ml) > leeway:
			return false
	return true

func _on_win() -> void:
	if completed: 
		return
	completed = true
	error_code.lamp_flash()
	AudioManager.play_success()
	await get_tree().create_timer(0.75).timeout
	if malfunction:
		malfunction.mark_solved()
	SceneSwitcher.close_overlay_scene()

## Zeigt den aktuellen Fuellstand in ml an.
func _update_fill_label() -> void:
	if is_instance_valid(fulestand):
		fulestand.set_source_text("Fuellstand: %d ml" % int(round(current_fill)))


func _on_return_bt_pressed() -> void:
	SceneSwitcher.close_overlay_scene()


func _on_reset_bt_pressed() -> void:
	reset_container()
