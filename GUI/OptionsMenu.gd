extends Control


var packed_controls_menu = preload("res://GUI/ControlsMenu.tscn")

signal back


func _ready():
	$PanelContainer/VBoxContainer/ButtonSystem.connect("pressed", self, "_on_system_pressed")
	$PanelContainer/VBoxContainer/ButtonControls.connect("pressed", self, "_on_controls_pressed")
	$PanelContainer/VBoxContainer/ButtonBack.connect("pressed", self, "_on_back_pressed")


func _on_system_pressed():
	pass

func _on_controls_pressed():
	if packed_controls_menu.can_instance():
		var controls_menu = packed_controls_menu.instance()
		add_child(controls_menu)
		$PanelContainer.visible = false
		yield(controls_menu, "back")
		controls_menu.queue_free()
		$PanelContainer.visible = true


func _on_back_pressed():
	emit_signal("back")
