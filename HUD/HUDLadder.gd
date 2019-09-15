extends Control
class_name HUDLadder

onready var horizon = $HorizonLine

var center_pos = Vector2.ZERO

var pitch_marker_scene = preload("res://HUD/HUDPitchMarker.tscn")
var pitch_markers = []
var pitch_marker_spacing = 20


func _ready():
	horizon.rect_pivot_offset = horizon.rect_size / 2
	center_pos = rect_size / 2 - horizon.rect_size / 2
	
	for i in range(-85, 90, 5):
		if i == 0:
			continue
		var marker = pitch_marker_scene.instance()
		horizon.add_child(marker)
		pitch_markers.append(marker)
		marker.update_marker(i)
		marker.rect_position = Vector2(horizon.rect_size.x / 2, -i * pitch_marker_spacing)

func update_ladder(pitch : float, roll : float):
	horizon.rect_rotation = rad2deg(roll)
	horizon.rect_position = center_pos + rad2deg(pitch * pitch_marker_spacing) * Vector2(-sin(roll), cos(roll))
