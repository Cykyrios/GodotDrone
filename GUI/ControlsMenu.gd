extends Control


var packed_calibration_menu = preload("res://GUI/CalibrationMenu.tscn")

signal back


func _ready():
	$VBoxContainer/ButtonCalibrate.connect("pressed", self, "_on_calibrate_pressed")
	$VBoxContainer/ButtonBack.connect("pressed", self, "_on_back_pressed")


func _on_calibrate_pressed():
	if packed_calibration_menu.can_instance():
		var calibration_menu = packed_calibration_menu.instance()
		add_child(calibration_menu)
		$VBoxContainer.visible = false
		yield(calibration_menu, "back")
		calibration_menu.queue_free()
		$VBoxContainer.visible = true


func _on_back_pressed():
	emit_signal("back")
