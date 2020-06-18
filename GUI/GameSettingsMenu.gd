extends MarginContainer


signal back


func _ready():
	$PanelContainer/VBoxContainer/HBoxContainer/ButtonBack.connect("pressed", self, "_on_back_pressed")


func _on_back_pressed():
	emit_signal("back")
