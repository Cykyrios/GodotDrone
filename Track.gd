tool
extends Spatial
class_name Track


var checkpoints = []
export (String, MULTILINE) var course
var current_checkpoint = null
var current = 0

export (int, 1, 100) var laps = 3
var current_lap = 1
var lap_start = 0
var lap_end = 0


func _ready():
	if Engine.editor_hint:
		return
	
	if checkpoints.empty():
		for child in get_children():
			if child is Gate:
				for c in child.get_children():
					if c is Checkpoint:
						checkpoints.append(c)
			elif child is Checkpoint:
				checkpoints.append(child)
	
	for cp in checkpoints:
		cp.connect("passed", self, "_on_checkpoint_passed")
	
	update_course()


func update_course():
	if course == "":
		course = []
		for i in range(checkpoints.size()):
			course.append(str(i))
	else:
		course = course.replace("\n", ",")
		course = course.replace(" ", "")
		var temp_course = course.split(",")
		course = []
		for i in range(temp_course.size()):
			course.append(temp_course[i])
		while course.find("") != -1:
			course.erase("")
	
	if !course.has("lap_start"):
		course.push_front("lap_start")
	if !course.has("lap_end"):
		course.push_back("lap_end")
	lap_start = course.find("lap_start")
	lap_end = course.find("lap_end")
	if lap_start != -1:
		course.remove(lap_start)
		lap_end -= 1
	else:
		lap_start = 0
	if lap_end != -1:
		course.remove(lap_end)
		lap_end -= 1
	else:
		lap_end = course.size() - 1
	
	reset_track()


#func _enter_tree():
#	if Engine.editor_hint:
#		if checkpoints.empty():
#			for g in get_children():
#				if g is Gate:
#					for c in g.checkpoints:
#						checkpoints.append(c)
#		for c in checkpoints:
#			c.set_area_visible(true)
#			c.mat.set_shader_param("Editor", true)
#			if c.backward:
#				c.mat.set_shader_param("CheckpointBackward", true)


func _on_checkpoint_passed(cp):
	if cp != current_checkpoint:
		return
	
	current_checkpoint.set_active(false)
	if current == course.size() - 1 and current_lap == laps:
		print("Finished!")
	else:
		activate_next_checkpoint()


func activate_next_checkpoint():
	if current >= lap_end and current_lap < laps:
		current_lap += 1
		current = lap_start
	else:
		current += 1
	var new_cp = [course[current], false]
	if new_cp[0].ends_with("b"):
		new_cp[0] = new_cp[0].rstrip("b")
		new_cp[1] = true
	current_checkpoint = checkpoints[new_cp[0].to_int()]
	current_checkpoint.set_backward(new_cp[1])
	current_checkpoint.set_active(true)
	print("Next: %s, %d/%d, lap %d/%d" % [current_checkpoint, current, course.size(), current_lap, laps])


func reset_track():
	if current_checkpoint != null:
		current_checkpoint.set_active(false)
	current_lap = 1
	current = -1
	print(checkpoints)
	activate_next_checkpoint()
