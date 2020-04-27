extends Control


var packed_controls_menu = preload("res://GUI/ControlsMenu.tscn")

signal back


func _ready():
	$VBoxContainer/ButtonSystem.connect("pressed", self, "_on_system_pressed")
	$VBoxContainer/ButtonControls.connect("pressed", self, "_on_controls_pressed")
	$VBoxContainer/ButtonBack.connect("pressed", self, "_on_back_pressed")


func _on_system_pressed():
	pass

func _on_controls_pressed():
	if packed_controls_menu.can_instance():
		var controls_menu = packed_controls_menu.instance()
		add_child(controls_menu)
		$VBoxContainer.visible = false
		yield(controls_menu, "back")
		controls_menu.queue_free()
		$VBoxContainer.visible = true


func _on_back_pressed():
	emit_signal("back")
