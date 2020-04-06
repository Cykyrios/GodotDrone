tool
extends Spatial
class_name Gate

var checkpoints = []


func _ready():
	for c in get_children():
		if c is Checkpoint:
			checkpoints.append(c as Checkpoint)


func _enter_tree():
	if Engine.editor_hint and checkpoints.empty():
		for c in get_children():
			if c is Checkpoint:
				checkpoints.append(c as Checkpoint)
		for c in checkpoints:
			c.set_area_visible(true)
