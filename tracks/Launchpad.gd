extends Spatial
class_name Launchpad


var launch_areas: Array = []


func _ready():
	for child in get_children():
		if child is LaunchArea:
			launch_areas.append(child)
