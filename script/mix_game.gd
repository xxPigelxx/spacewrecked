extends CanvasLayer

@onready var container_sprite: Sprite2D = $Container/ContainerSprite
@onready var color_rect: ColorRect = $Container/ColorRect
@onready var liquid_line: AnimatedSprite2D = $Container/ColorRect/LiquidLine

@export var max_fill: float = 140.0
## Rezept: jeder Eintrag ist { "bottle_name": String, "target_pct": float (0–100) }
## Beispiel: [{"bottle_name":"Wasser","target_pct":50.0},{"bottle_name":"Oel","target_pct":25.0}]
@export var recipe: Array[Dictionary] = [{"bottle_name":"Wasser","target_pct":50.0},{"bottle_name":"Oel","target_pct":25.0}]

## Spielraum in Prozentpunkten (±). 10 = ±10%
@export_range(1.0, 30.0, 0.5, "suffix:%") var leeway: float = 10.0

## Muss der Behälter komplett voll sein oder reicht die richtige Mischung?
@export var require_full: bool = true

@export var puzzel_id: String = "Mix1"

var current_fill: float = 0.0
var bottles: Array = []
var mixed_color: Color = Color(0, 0, 0, 1)

## Wie viel wurde von jeder Flasche (per bottle_name) eingefüllt
var poured_per_bottle: Dictionary = {}

var full_liquid_height: float
var bottom_y: float

func _ready() -> void:
	full_liquid_height = color_rect.size.y
	bottom_y = color_rect.position.y + color_rect.size.y
	update_visual()

func add_to_container(bottle, amount: float) -> void:
	if not bottle.is_in_group("Bottle"):
		return

	if bottle not in bottles:
		bottles.append(bottle)

	current_fill = min(current_fill + amount, max_fill)
	update_mixed_color(bottle.bottle_color, amount)

	# Wie viel wurde von dieser Flasche eingefüllt verfolgen
	var bname: String = bottle.bottle_name
	poured_per_bottle[bname] = poured_per_bottle.get(bname, 0.0) + amount

	update_visual()
	if _check_win():
		_on_win()

func update_mixed_color(new_color: Color, amount: float) -> void:
	if current_fill <= 0.0:
		mixed_color = new_color
		return
	
	var mix_strength := amount / current_fill
	mixed_color = mixed_color.lerp(new_color, mix_strength)

func update_visual() -> void:
	var percent := current_fill / max_fill
	var new_height := full_liquid_height * percent
	
	color_rect.size.y = new_height
	color_rect.position.y = bottom_y - new_height
	color_rect.color = mixed_color
	liquid_line.modulate = mixed_color
	if percent >= 0.01:
		liquid_line.visible = true
		liquid_line.play()
	else:
		liquid_line.visible = false
		liquid_line.stop()
		
func reset_container() -> void:
	bottles.clear()
	current_fill = 0.0
	mixed_color = Color(0, 0, 0, 1)
	poured_per_bottle.clear()
	update_visual()

func is_full() -> bool:
	return current_fill >= max_fill

## Gibt für jeden Rezept-Eintrag zurück wie weit er vom Ziel entfernt ist (0.0 = perfekt).
## Gibt ein leeres Array zurück wenn kein Rezept definiert ist.
func get_recipe_deltas() -> Array[float]:
	if recipe.is_empty() or current_fill <= 0.0:
		return []
	var deltas: Array[float] = []
	for entry in recipe:
		var bname: String = entry.get("bottle_name", "")
		var target_pct: float = entry.get("target_pct", 0.0)
		var actual_amount: float = poured_per_bottle.get(bname, 0.0)
		var actual_pct: float = (actual_amount / current_fill) * 100.0
		deltas.append(abs(actual_pct - target_pct))
	return deltas

func _check_win() -> bool:
	# Kein Rezept definiert — nur voll sein reicht
	if recipe.is_empty():
		return is_full()

	# Behälter muss voll sein wenn require_full aktiv
	if require_full and not is_full():
		return false

	# Muss mindestens etwas drin sein
	if current_fill <= 0.0:
		return false

	# Jeden Rezept-Eintrag prüfen
	for entry in recipe:
		var bname: String = entry.get("bottle_name", "")
		var target_pct: float = entry.get("target_pct", 0.0)
		var actual_amount: float = poured_per_bottle.get(bname, 0.0)
		var actual_pct: float = (actual_amount / current_fill) * 100.0
		if abs(actual_pct - target_pct) > leeway:
			return false

	return true

func _on_win() -> void:
	print("WIN! Rezept stimmt!")
	GameState.solve_puzzle(puzzel_id)
	SceneSwitcher.close_overlay_scene()
	# Hier GameManager oder Signal einhängen
	# Beispiel: GameManager.puzzle_solved("mix_game")


func _on_return_bt_pressed() -> void:
	SceneSwitcher.close_overlay_scene()


func _on_reset_bt_pressed() -> void:
	reset_container()
