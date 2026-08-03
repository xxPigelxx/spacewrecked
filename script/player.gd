extends CharacterBody2D

@export var speed := 300.0
@export var run_speed := 600.0
## Abstand zwischen zwei Schrittgeraeuschen in Sekunden (Schritt-Takt).
@export var step_interval := 0.5

@onready var player_sprite: AnimatedSprite2D = $PlayerSprite

@onready var player_light: PointLight2D = $playerLight
@onready var flashlights: PointLight2D = $Flashlights
@onready var puuftrail: CPUParticles2D = $PlayerSprite/puuftrail
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var label: DyslexiaLabel = $Label
@onready var label_backlight: PointLight2D = $Label/LabelBacklight


var ship_lights_on := false
var has_manual := false
var _step_t := 0.0
## Alle Interaktions-Bereiche, in denen der Spieler gerade steht. Die Bereiche
## ueberlappen sich (Tuer und Handbuch liegen z.B. nur 5 px auseinander, der
## Spieler ist 33 px breit). Ohne diese Liste loescht der zuerst verlassene
## Bereich den Prompt eines Bereichs, in dem der Spieler noch drin steht.
var _nearby: Array[Interactable] = []

func _ready() -> void:
	ship_lights_on = not GameState.is_system_broken("strom")
	has_manual = GameState.manule_aquiered

	switch_lights(ship_lights_on)

	GameState.manual_acquired_changed.connect(_on_manual_changed)
	GameState.broken_systems_changed.connect(_on_strom_changed)
	
	label.visible = false
	flashlights.visible = false

	# Der Prompt wird bei jedem Betreten neu gesetzt. Ohne leeren Quelltext haelt
	# DyslexiaLabel den Text aus der Szene fest und schreibt ihn bei jeder
	# Stress-Aenderung wieder ueber den gerade angezeigten Prompt.
	label.set_source_text("")
	
func _on_strom_changed() -> void:
	switch_lights(not GameState.is_system_broken("strom"))

func _physics_process(delta: float) -> void:
	# Bei offenem Overlay (Raetsel, Tastenfeld) laeuft die Schiffsszene bewusst
	# weiter — nur der Spieler haelt an. Sonst wuerde er hinter dem Raetsel
	# herumlaufen, waehrend die Maus dort zieht. Beim Pausenmenue kommen wir hier
	# gar nicht an: das friert die Szene weiterhin komplett ein.
	if SceneSwitcher.is_overlay_open:
		velocity = Vector2.ZERO
		player_sprite.play("default")
		player_sprite.speed_scale = 1.0
		puuftrail.emitting = false
		_step_t = 0.0
		return

	var direction := Vector2.ZERO
	var current_speed :=  speed

	if Input.is_action_just_pressed("pause"):
		SceneSwitcher.open_overlay_scene("res://Scenes/Menu/PauseMenu.tscn", false, false, true)
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	if Input.is_action_pressed("move_up"):
		direction.y -= 1
	if Input.is_action_pressed("run"):
		current_speed = run_speed

	direction = direction.normalized()
	velocity = direction * current_speed
	move_and_slide()

	if Input.is_action_just_pressed("flash_light"):
		toggle_flashlight()

	
	flashlights.look_at(get_global_mouse_position())
	
	
	
	# Schritt-Takt und Animation skalieren mit dem Tempo, sonst laufen
	# Sound und Beine beim Rennen aus dem Takt.
	var speed_ratio := current_speed / speed

	if direction != Vector2.ZERO:
		player_sprite.play("walk")
		player_sprite.speed_scale = speed_ratio
		player_sprite.rotation = direction.angle()
		puuftrail.emitting = true
		puuftrail.speed_scale = speed_ratio
		# Schritt im Takt abspielen, nicht jeden Frame neu starten.
		_step_t -= delta
		if _step_t <= 0.0:
			audio_stream_player.play()   # Randomizer waehlt einen zufaelligen Schritt
			_step_t = step_interval / speed_ratio
	else:
		player_sprite.play("default")
		player_sprite.speed_scale = 1.0
		puuftrail.emitting = false
		_step_t = 0.0   # beim naechsten Loslaufen sofort ein Schritt
	
func switch_lights(val: bool) -> void:
	ship_lights_on = val
	player_light.visible = not ship_lights_on
	label_backlight.visible = not ship_lights_on
	label.add_theme_color_override("default_color", Color.BLACK if val else Color.WHITE)
	if ship_lights_on:
		flashlights.visible = false

func toggle_flashlight() -> void:
	if not has_manual:
		return

	if ship_lights_on:
		return

	flashlights.visible = !flashlights.visible

func _on_manual_changed(acquired: bool) -> void:
	has_manual = acquired

	if not has_manual:
		flashlights.visible = false

## Bereich betreten: sein Prompt wird angezeigt, der zuletzt betretene gewinnt.
func show_prompt(source: Interactable) -> void:
	if not _nearby.has(source):
		_nearby.append(source)
	_refresh_prompt()

func set_text_visable():
	label.visible = true

## Bereich verlassen. Steht der Spieler noch in einem anderen, uebernimmt dessen
## Prompt — erst wenn keiner mehr uebrig ist, verschwindet die Anzeige.
func hide_prompt(source: Interactable) -> void:
	_nearby.erase(source)
	_refresh_prompt()

func _refresh_prompt() -> void:
	while not _nearby.is_empty():
		var top: Interactable = _nearby.back()
		if is_instance_valid(top):
			label.text = "[wave amp=20 freq=4]%s[/wave]" % top.prompt_text
			label.visible = true
			return
		# Bereich wurde freigegeben (Handbuch aufgesammelt) — naechsten pruefen.
		_nearby.pop_back()
	label.text = ""
