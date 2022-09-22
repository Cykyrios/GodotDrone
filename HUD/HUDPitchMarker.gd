extends Control


@export var angle := 0

@onready var left_half := $HBoxContainer/LeftHalf
@onready var right_half := $HBoxContainer/RightHalf

var texture_neg := load("res://Assets/HUD/PitchMarkerNegative.png")


func _ready() -> void:
	update_marker(angle)


func update_marker(a: int) -> void:
	angle = a
	if angle < 0:
		left_half.get_node("Line").texture = texture_neg
		right_half.get_node("Line").texture = texture_neg

	var text := "%02d" % angle
	left_half.get_node("Label").text = text
	right_half.get_node("Label").text = text
