extends Control


signal back


func _ready():
	$VBoxContainer/ButtonBack.connect("pressed", self, "_on_back_pressed")


func _on_back_pressed():
	emit_signal("back")
