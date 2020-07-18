extends Control


func update_rpm(rpm1: float, rpm2: float, rpm3: float, rpm4: float) -> void:
	$GridContainer/LabelMotor1.text = "%0d" % round(rpm1)
	$GridContainer/LabelMotor2.text = "%0d" % round(rpm2)
	$GridContainer/LabelMotor3.text = "%0d" % round(rpm3)
	$GridContainer/LabelMotor4.text = "%0d" % round(rpm4)
