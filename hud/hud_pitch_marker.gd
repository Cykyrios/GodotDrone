class_name HUDPitchMarker
extends Control


@export var angle := 0

@onready var left_label := %LeftLabel as Label
@onready var left_line := %LeftLine as NinePatchRect
@onready var right_line := %RightLine as NinePatchRect
@onready var right_label := %RightLabel as Label

var texture_neg := preload("res://Assets/HUD/PitchMarkerNegative.png")


func _ready() -> void:
	update_marker(angle)


func update_marker(new_angle: int) -> void:
	angle = new_angle
	if angle < 0:
		left_line.texture = texture_neg
		right_line.texture = texture_neg

	var text := "%02d" % [angle]
	left_label.text = text
	right_label.text = text
