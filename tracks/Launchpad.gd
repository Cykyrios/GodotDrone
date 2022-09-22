extends Node3D
class_name Launchpad


var launch_areas := []


func _ready() -> void:
	for child in get_children():
		if child is LaunchArea:
			launch_areas.append(child)
