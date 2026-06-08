extends CanvasLayer

@onready var manual: Control = $ManualRoot


func activate(val: String = "Home"):
	visible = true
	manual.open(val)
	
