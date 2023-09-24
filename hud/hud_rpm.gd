class_name HUDRPM
extends Control


func update_rpm(rpm1: float, rpm2: float, rpm3: float, rpm4: float) -> void:
	%LabelMotor1.text = "%5d" % [roundi(rpm1)]
	%LabelMotor2.text = "%5d" % [roundi(rpm2)]
	%LabelMotor3.text = "%5d" % [roundi(rpm3)]
	%LabelMotor4.text = "%5d" % [roundi(rpm4)]
