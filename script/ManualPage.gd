# ManualPage.gd — attach to ManualRoot (Control)
extends Control

@onready var side_button  : Button        = $SideButton
@onready var tab_container: TabContainer  = $PanelContainer/TabContainer
@onready var prev_btn     : Button        = $Footer/PrevButton
@onready var next_btn     : Button        = $Footer/NextButton

var _open := false

func _ready() -> void:
	side_button.toggled.connect(_on_side_toggled)
	prev_btn.pressed.connect(_on_prev)
	next_btn.pressed.connect(_on_next)
	tab_container.tab_changed.connect(_on_tab_changed)
	_update_buttons()

func open(tab_name := "") -> void:
	if not _open:
		_slide_in()
	if tab_name != "":
		var tab = $PanelContainer/TabContainer
		for i in tab.get_tab_count():
			if tab.get_tab_title(i) == tab_name:
				tab.current_tab = i
				break

func set_stress(level: float) -> void:
	DyslexiaManager.stress = level

func _on_prev() -> void:
	tab_container.current_tab = max(0, tab_container.current_tab - 1)

func _on_next() -> void:
	tab_container.current_tab = min(tab_container.get_tab_count() - 1, tab_container.current_tab + 1)

func _on_tab_changed(_idx: int) -> void:
	_update_buttons()
	# Pause wave animation on hidden tabs to prevent frame drops
	for i in tab_container.get_tab_count():
		var page := tab_container.get_child(i)
		page.process_mode = Node.PROCESS_MODE_DISABLED if i != _idx else Node.PROCESS_MODE_INHERIT

func _update_buttons() -> void:
	prev_btn.disabled = (tab_container.current_tab == 0)
	next_btn.disabled = (tab_container.current_tab == tab_container.get_tab_count() - 1)

func _slide_in() -> void:
	_open = true
	_tween_to(get_viewport_rect().size.x - size.x)
	side_button.button_pressed = true
	side_button.text = "Schliessen"

func _slide_out() -> void:
	_open = false
	_tween_to(get_viewport_rect().size.x)
	side_button.button_pressed = false
	side_button.text = "Handbuch"

func _tween_to(tx: float) -> void:
	var t := create_tween()
	t.tween_property(self, "position:x", tx, 0.4)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_side_toggled(on: bool) -> void:
	if on: _slide_in()
	else: _slide_out()
