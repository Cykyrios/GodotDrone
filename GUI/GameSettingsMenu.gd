extends MarginContainer


signal back


func _ready() -> void:
	var _discard = $PanelContainer/VBoxContainer/HBoxContainer/ButtonBack.connect("pressed", self, "_on_back_pressed")


func _on_back_pressed() -> void:
	emit_signal("back")
