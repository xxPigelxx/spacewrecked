# ManualPage.gd
# Attach to your manual overlay scene root.
#
# SCENE TREE SETUP:
#   CanvasLayer
#   └── ManualRoot (Control)          ← attach this script here
#       ├── BookContainer (HBoxContainer)
#       │   ├── Cover (Panel)
#       │   │   ├── CoverTitle (Label)
#       │   │   ├── CoverSubtitle (Label)
#       │   │   ├── Divider (HSeparator)
#       │   │   ├── TOCLabel (Label)
#       │   │   └── TOCList (VBoxContainer)   ← TOC buttons go here
#       │   └── PagePanel (Panel)
#       │       ├── PageHeader (HBoxContainer)
#       │       │   ├── SectionLabel (Label)
#       │       │   └── PageNumLabel (Label)
#       │       ├── PageTitle (Label)
#       │       ├── BodyLabel (RichTextLabel)
#       │       ├── WarningBox (PanelContainer)
#       │       │   └── WarningLabel (RichTextLabel)
#       │       ├── StepList (VBoxContainer)
#       │       └── Footer (HBoxContainer)
#       │           ├── PrevButton (Button)
#       │           └── NextButton (Button)
#       └── CloseButton (Button)

extends Control

# ─────────────────────────────────────────────
#  EXPORTS — drag nodes in the Inspector
# ─────────────────────────────────────────────

@export var toc_list: VBoxContainer
@export var section_label: Label
@export var page_num_label: Label
@export var page_title_label: Label
@export var body_label: RichTextLabel
@export var warning_box: Control          # hide when warning_text is empty
@export var warning_label: RichTextLabel
@export var step_list: VBoxContainer
@export var prev_button: Button
@export var next_button: Button

## Drag all your PageConfig .tres files in here in order.
@export var pages: Array[PageConfig] = []

@onready var side_button: Button = $BookContainer/SideButton


# ─────────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────────

var _current_index: int = 0
var _toc_buttons: Array[Button] = []

@onready var open_x := position.x -650
@onready var closed_x := position.x
# ─────────────────────────────────────────────
#  LIFECYCLE
# ─────────────────────────────────────────────

func _ready() -> void:
	_build_toc()
	_load_page(_current_index)
	prev_button.pressed.connect(_on_prev)
	next_button.pressed.connect(_on_next)



# ─────────────────────────────────────────────
#  PUBLIC API
# ─────────────────────────────────────────────

## Call from your game to open the manual at a specific page.
## Pass the page_id string defined in your PageConfig.
##
## Example:


func open(page_id: String = "") -> void:
	if page_id != "":
		for i in pages.size():
			if pages[i].page_id == page_id:
				_current_index = i
				break

	_load_page(_current_index)
	show()


# ─────────────────────────────────────────────
#  INTERNAL
# ─────────────────────────────────────────────

func _build_toc() -> void:
	# Clear any existing children
	for child in toc_list.get_children():
		child.queue_free()
	_toc_buttons.clear()

	for i in pages.size():
		var config := pages[i]
		var btn := Button.new()
		btn.text = "%s  %s" % [config.section_label, config.page_title]
		btn.flat = true
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_toc_pressed.bind(i))
		toc_list.add_child(btn)
		_toc_buttons.append(btn)


func _load_page(index: int) -> void:
	if pages.is_empty():
		push_warning("ManualPage: no pages assigned in the Inspector.")
		return

	_current_index = clampi(index, 0, pages.size() - 1)
	var config := pages[_current_index]

	# Tell DyslexiaManager about this page
	DyslexiaManager.load_page(config)

	# Header
	section_label.text = config.section_label
	page_num_label.text = "p. %02d" % config.page_number
	page_title_label.text = config.page_title

	# Font
	DyslexiaManager.apply_font_to_label(body_label)

	# Body text
	body_label.text = DyslexiaManager.process_text()

	# Warning box
	if config.warning_text.strip_edges() != "":
		warning_box.show()
		warning_label.text = config.warning_text
	else:
		warning_box.hide()

	# Steps
	for child in step_list.get_children():
		child.queue_free()

	for i in config.steps.size():
		var lbl := RichTextLabel.new()
		lbl.bbcode_enabled = true
		lbl.fit_content = true
		lbl.text = "%d.  %s" % [i + 1, config.steps[i]]
		DyslexiaManager.apply_font_to_label(lbl)
		step_list.add_child(lbl)

	# Nav buttons
	prev_button.disabled = _current_index == 0
	next_button.disabled = _current_index == pages.size() - 1

	# Highlight active TOC entry
	for i in _toc_buttons.size():
		_toc_buttons[i].button_pressed = (i == _current_index)

func slide_to(target_x: float, duration := 0.4) -> void:
	var tween = create_tween()
	tween.tween_property(self, "position:x", target_x, duration)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

func _on_toc_pressed(index: int) -> void:
	_load_page(index)


func _on_prev() -> void:
	_load_page(_current_index - 1)


func _on_next() -> void:
	_load_page(_current_index + 1)


func _on_side_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		slide_to(open_x)
		side_button.text = "Close"
	else:
		slide_to(closed_x)
		side_button.text = "Open"
