extends MarginContainer


signal back


func _ready() -> void:
	var _discard = $PanelContainer/VBoxContainer/HBoxContainer/ButtonBack.connect("pressed", self, "_on_back_pressed")


func _input(event):
	if event is InputEventKey and event.is_pressed() and event.scancode == KEY_ESCAPE:
		accept_event()
		emit_signal("back")


func _on_back_pressed() -> void:
	emit_signal("back")
