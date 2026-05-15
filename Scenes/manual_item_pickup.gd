extends Interactable

@onready var manual: Control = $"../../Manual/ManualRoot"


func _action() -> void:
	manual.activate()
	self.queue_free()
