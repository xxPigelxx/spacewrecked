extends Control
@onready var side_button  : Button        = $SideButton
@onready var tab_container: TabContainer  = $PanelContainer/TabContainer
@onready var prev_btn     : Button        = $Footer/PrevButton
@onready var next_btn     : Button        = $Footer/NextButton

var _open := false
var _page_times: Dictionary = {}
var _current_tab_start_ms: int = -1

func _ready() -> void:
	side_button.toggled.connect(_on_side_toggled)
	prev_btn.pressed.connect(_on_prev)
	next_btn.pressed.connect(_on_next)
	tab_container.tab_changed.connect(_on_tab_changed)
	_update_buttons()
	GameState.run_finished.connect(_on_run_finished)

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
	if _open:
		_stop_tab_timer()
		_start_tab_timer()
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
	_start_tab_timer()

func _slide_out() -> void:
	_open = false
	_tween_to(get_viewport_rect().size.x)
	side_button.button_pressed = false
	side_button.text = "Handbuch"
	_stop_tab_timer()

func _tween_to(tx: float) -> void:
	var t := create_tween()
	t.tween_property(self, "position:x", tx, 0.4)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_side_toggled(on: bool) -> void:
	if on: _slide_in()
	else: _slide_out()

# ---- Zeit-Tracking ----

func _start_tab_timer() -> void:
	_current_tab_start_ms = Time.get_ticks_msec()

func _stop_tab_timer() -> void:
	if _current_tab_start_ms == -1:
		return
	var elapsed := (Time.get_ticks_msec() - _current_tab_start_ms) / 1000.0
	var tab_name := tab_container.get_tab_title(tab_container.current_tab)
	_page_times[tab_name] = _page_times.get(tab_name, 0.0) + elapsed
	_current_tab_start_ms = -1

func reset_page_times() -> void:
	_page_times.clear()
	if _open:
		_start_tab_timer()

## Run ist vorbei — Manual evtl. noch offen, letzten Timer sauber abschliessen,
## dann eigenen Sheet-Eintrag verschicken (verknuepft ueber run_id).
func _on_run_finished(_results: Dictionary) -> void:
	if _open:
		_stop_tab_timer()
	ResultsExporter.deliver_manual_times(GameState.get_current_run_id(), _page_times.duplicate())
