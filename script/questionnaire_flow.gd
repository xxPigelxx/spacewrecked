extends Control
## Fuehrt durch die Schritte eines Fragebogen-Blocks (Intro, TLX, Fragebogen).
##
## Sichtbar ist immer genau ein Schritt. Der Weiter-Button gehoert dem Ablauf
## und sitzt dadurch in jedem Schritt an derselben Stelle — ein wandernder
## Button kostet den Teilnehmer Zeit, und die landet in den Messwerten.
##
## Nach dem letzten Schritt:
##   Pre  -> Spielzeit-Uhr starten, weiter ins MainGame
##   Post -> senden, und erst nach erfolgreichem Upload zum Endscreen

## "pre" oder "post". Wird beim Einsammeln an die Schritte weitergereicht, damit
## die Einstellung nicht in jeder Panel-Szene einzeln stimmen muss — ein falsch
## gesetzter Block faellt sonst erst in der Auswertung auf.
@export var block: String = "pre"

## Szene nach dem letzten Schritt.
@export_file("*.tscn") var next_scene: String = ""

## Die Schritt-Panels in der Reihenfolge, in der sie drankommen.
@export var steps: Array[Control] = []

## Werden ueber ihren Namen gefunden, damit sie nicht im Inspector verdrahtet
## werden muessen. Das StatusLabel gibt es nur im Post-Block.
@onready var next_button: Button = get_node_or_null("NextButton")
@onready var status_label: Label = $NextButton/StatusLabel

var _index := -1


func _ready() -> void:
	if status_label:
		status_label.visible = false
	next_button.pressed.connect(_on_next_pressed)

	for step in steps:
		step.visible = false

	_next_step()


## Der Button gehoert dem Ablauf, also fragt der Ablauf den aktuellen Schritt,
## ob es weitergehen darf.
func _process(_delta: float) -> void:
	if _index < 0 or _index >= steps.size():
		return
	next_button.disabled = not steps[_index].is_complete()


func _on_next_pressed() -> void:
	# Nach dem letzten Schritt gibt es nichts mehr einzusammeln — dann ist der
	# Button der zweite Sendeversuch.
	if _index >= steps.size():
		_send()
		return
	steps[_index].collect(block)
	_next_step()


func _next_step() -> void:
	if _index >= 0:
		steps[_index].visible = false
	_index += 1

	if _index < steps.size():
		steps[_index].visible = true
		# Beim letzten Schritt des Post-Blocks geht es nicht weiter, sondern raus.
		var is_last := _index == steps.size() - 1
		next_button.text = "Absenden" if is_last and block == "post" else "Weiter"
		return

	if block == "post":
		_send()
	else:
		# Ab hier laeuft das Spiel — die Fragebogen-Minuten davor zaehlen nicht mit.
		GameState.start_setup()
		SceneSwitcher.switch_scene(next_scene)


## Schickt den gesamten Durchlauf ab — der einzige Sende-Punkt der Studie.
## Weiter geht es erst, wenn die Zeile angekommen ist; sonst wird der Button
## zum zweiten Versuch. Mehr Wiederholungslogik braucht es nicht, der
## Teilnehmer sitzt davor.
func _send() -> void:
	next_button.disabled = true
	if status_label:
		status_label.visible = true
		status_label.text = "Wird gesendet..."

	if await ResultsExporter.submit():
		SceneSwitcher.switch_scene(next_scene)
		return

	if status_label:
		status_label.text = "Senden fehlgeschlagen."
	next_button.text = "Nochmal senden"
	next_button.disabled = false
