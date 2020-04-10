tool
extends Spatial
class_name Track


var checkpoints = []
export (Array) var course = []
var current = 0


func _ready():
	if Engine.editor_hint:
		return
	
	for g in get_children():
		if g is Gate:
			for c in g.checkpoints:
				checkpoints.append(c)
	
	for c in checkpoints:
		c.connect("passed", self, "_on_checkpoint_passed")
	
	if course == []:
		course = checkpoints
	
	course[current].set_active(true)


func _enter_tree():
	if Engine.editor_hint:
		if checkpoints.empty():
			for g in get_children():
				if g is Gate:
					for c in g.checkpoints:
						checkpoints.append(c)
		for c in checkpoints:
			c.set_area_visible(true)
			c.mat.set_shader_param("Editor", true)
			if c.backward:
				c.mat.set_shader_param("CheckpointBackward", true)


func _on_checkpoint_passed(cp):
	if cp != course[current]:
		return
	course[current].set_active(false)
	if current < course.size() - 1:
		current += 1
		course[current].set_active(true)
		print("Next: %d/%d" % [current + 1, course.size()])
	else:
		print("Finished!")


func reset():
	course[current].set_active(false)
	current = 0
	course[current].set_active(true)
