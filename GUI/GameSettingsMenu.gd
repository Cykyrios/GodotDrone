extends MarginContainer


signal back


func _ready() -> void:
	var _discard = $PanelContainer/VBoxContainer/HBoxContainer/ButtonBack.pressed.connect(_on_back_pressed)


func _input(event):
	if event.is_action("ui_cancel") and event.is_pressed() and not event.is_echo():
		accept_event()
		back.emit()


func _on_back_pressed() -> void:
	back.emit()
