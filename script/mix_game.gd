extends CanvasLayer

@onready var container_sprite: Sprite2D = $Container/ContainerSprite
@onready var color_rect: ColorRect = $Container/ColorRect
@onready var liquid_line: AnimatedSprite2D = $Container/ColorRect/LiquidLine
@onready var recipe_label: RichTextLabel = $RecipePanel/RichTextLabel
@onready var fulestand: RichTextLabel = $Fulestand
@onready var error_code: Node2D = $ErrorCode

@export var max_fill: float = 140.0
@export var recipe: Array[Dictionary] = [{"bottle_name":"Wasser","target_pct":20.0},{"bottle_name":"Xytherium","target_pct":12.0},{"bottle_name":"Hyperion","target_pct":23.0},{"bottle_name":"Vortex","target_pct":25.0} ]

## Spielraum in Prozentpunkten (±). 10 = ±10%
@export_range(1.0, 30.0, 0.5, "suffix:%") var leeway: float = 10.0

## Muss der Behälter komplett voll sein oder reicht die richtige Mischung?
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

func _ready() -> void:
	full_liquid_height = color_rect.size.y
	bottom_y = color_rect.position.y + color_rect.size.y
	call_deferred("update_visual")
	call_deferred("_update_recipe_label")

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
	_update_recipe_label()
		
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
	if recipe.is_empty():
		return []
	var deltas: Array[float] = []
	for entry in recipe:
		var bname: String = entry.get("bottle_name", "")
		var target_pct: float = entry.get("target_pct", 0.0)
		var actual_pct: float = (poured_per_bottle.get(bname, 0.0) / max_fill) * 100.0
		deltas.append(abs(actual_pct - target_pct))
	return deltas

func _check_win() -> bool:
	if recipe.is_empty():
		return is_full()
	if current_fill <= 0.0:
		return false
	for entry in recipe:
		var bname: String = entry.get("bottle_name", "")
		var target_pct: float = entry.get("target_pct", 0.0)
		var actual_pct: float = (poured_per_bottle.get(bname, 0.0) / max_fill) * 100.0
		if abs(actual_pct - target_pct) > leeway:
			return false
	return true

func _on_win() -> void:
	if completed: 
		return
	completed = true
	print("WIN! Rezept stimmt!")
	error_code.lamp_flash()
	AudioManager.play_success()
	await get_tree().create_timer(0.75).timeout
	if malfunction:
		malfunction.mark_solved()
	SceneSwitcher.close_overlay_scene()

## Zeigt Rezept-Ziele und aktuelle Prozentwerte live an.
func _update_recipe_label() -> void:
	if not is_instance_valid(recipe_label):
		return
	if recipe.is_empty():
		recipe_label.text = "[b]Kein Rezept gesetzt[/b]"
		return
	var lines := "[b]Rezept[/b]\n"
	for entry in recipe:
		var bname: String = entry.get("bottle_name", "?")
		var target: float = entry.get("target_pct", 0.0)
		var actual: float = (poured_per_bottle.get(bname, 0.0) / max_fill) * 100.0
		var ok: bool = abs(actual - target) <= leeway
		var col: String = "#44cc44" if ok else "#cc4444"
		lines += "[color=%s]%s: %d%% / Ziel %d%% (Spielraum \u00b1%d%%)[/color]\n" % [col, bname, int(actual), int(target), int(leeway)]
	lines += "\nFuellstand: %d%%" % int((current_fill / max_fill) * 100.0)
	recipe_label.text = lines
	if is_instance_valid(fulestand):
		fulestand.text = "Fuellstand: %d%%" % int((current_fill / max_fill) * 100.0)


func _on_return_bt_pressed() -> void:
	SceneSwitcher.close_overlay_scene()


func _on_reset_bt_pressed() -> void:
	reset_container()
