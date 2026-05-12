extends Node2D

# The raw manual text — later this comes from your level data
const RAW_TEXT = "Locate the red valve marked OXYGEN-A on panel 6. 
Turn the handle counter-clockwise three times until 
the pressure gauge reads 0. Do not open the secondary 
valve before confirming the primary is sealed."

@onready var label := $RichTextLabel
@onready var slider := $HSlider
@onready var label2: Label = $HSlider/Label

func _ready() -> void:
	# Seed it so errors are consistent on this page
	DyslexiaManager.set_seed(1001)
	
	# Connect stress changes to re-render the text
	DyslexiaManager.stress_changed.connect(_on_stress_changed)
	
	# Connect slider to manually drive stress while testing
	slider.value_changed.connect(_on_slider_moved)
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01

func _on_stress_changed(_value: float) -> void:
	# Re-render the text every time stress updates
	label.text = DyslexiaManager.process_text()
	

func _on_slider_moved(value: float) -> void:
	DyslexiaManager.set_stress(value)
	label2.text = str(value)
