tool
extends Spatial
class_name Track


export (bool) var edit_track = false setget set_edit_track
export (int) var selected_checkpoint = -1 setget set_selected_checkpoint
export (String, MULTILINE) var course

var checkpoints = []
var current_checkpoint = null
var current = 0

export (int, 1, 100) var laps = 3
var current_lap = 1
var lap_start = 0
var lap_end = 0


func _ready():
	if Engine.editor_hint:
		return
	
	set_selected_checkpoint(-1)
	set_edit_track(false)
	
	get_checkpoints()
	
	for cp in checkpoints:
		cp.connect("passed", self, "_on_checkpoint_passed")
	
	update_course()


func get_checkpoints():
	checkpoints.clear()
	for child in get_children():
		if child is Gate:
			for c in child.get_children():
				if c is Checkpoint:
					checkpoints.append(c)
		elif child is Checkpoint:
			checkpoints.append(child)


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


func set_edit_track(edit : bool):
	if !Engine.editor_hint:
		return
	edit_track = edit
	if edit_track:
		get_checkpoints()
	for cp in checkpoints:
		cp.set_area_visible(edit_track)
		cp.mat.set_shader_param("Editor", edit_track)
		cp.mat.set_shader_param("Selected", false)
	if !edit_track:
		checkpoints.clear()
		selected_checkpoint = -1


func set_selected_checkpoint(selected : int):
	if !Engine.editor_hint:
		return
	var size = checkpoints.size()
	if size == 0:
		selected_checkpoint = -1
		return
	elif selected >= size:
		return
	elif selected < -1:
		checkpoints[selected_checkpoint].set_selected(false)
		return
	checkpoints[selected_checkpoint].set_selected(false)
	selected_checkpoint = selected
	checkpoints[selected_checkpoint].set_selected(true)


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


func reset_track():
	if current_checkpoint != null:
		current_checkpoint.set_active(false)
	current_lap = 1
	current = -1
	activate_next_checkpoint()
