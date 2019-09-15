extends Control

export (int) var angle = 0

onready var left_half = $HBoxContainer/LeftHalf
onready var right_half = $HBoxContainer/RightHalf


func _ready():
	update_marker(angle)


func update_marker(angle : int):
	if angle < 0:
		left_half.get_node("HorizontalLine").size_flags_vertical = SIZE_SHRINK_END
		right_half.get_node("HorizontalLine").size_flags_vertical = SIZE_SHRINK_END
	
	var text = "%02d" % angle
	left_half.get_node("Label").text = text
	right_half.get_node("Label").text = text
