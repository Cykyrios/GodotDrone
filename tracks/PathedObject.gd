tool
extends Path
class_name PathedObject


export (Mesh) var mesh: Mesh = null setget set_mesh
var multimesh: MultiMesh = null
export (String, MULTILINE) var spline_points := "" setget set_spline_points

export (float, 0, 10) var spacing := 1.0 setget set_spacing


func _ready() -> void:
	var _discard = connect("curve_changed", self, "_on_curve_changed")
	
	update_spline_points()
	
	if !multimesh:
		create_multimesh()
	
	update_multimesh()


func get_multimesh() -> MultiMesh:
	for child in get_children():
		if child is MultiMeshInstance:
			multimesh = child.multimesh
			break
	return multimesh


func set_mesh(m: Mesh) -> void:
	mesh = m
	if !get_multimesh():
		create_multimesh()
	multimesh.mesh = mesh
	update_multimesh()


func set_spacing(space: float) -> void:
	spacing = space
	update_multimesh()


func set_spline_points(points) -> void:
	var points_array := []
	points = points.replace("\n", "")
	var string_array: Array = points.split("]")
	string_array.remove(string_array.size() - 1)
	for string in string_array:
		if string.count("[") != 1:
			return
		else:
			string = string.replace("[", "")
		var vector_string: Array = string.split(")")
		vector_string.remove(vector_string.size() - 1)
		var vector_array := []
		for substring in vector_string:
			if substring.count("(") != 1:
				return
			else:
				substring = substring.replace("(", "")
				substring = substring.replace(" ", "")
				if substring.begins_with(","):
					substring = substring.lstrip(",")
				var v: Array = substring.split(",")
				if v.size() == 3:
					vector_array.append(Vector3(v[0].to_float(), v[1].to_float(), v[2].to_float()))
				else:
					return
		while vector_array.size() < 3:
			vector_array.append(Vector3(0.0, 0.0, 0.0))
		points_array.append(vector_array)
	spline_points = ""
	curve.clear_points()
	for point in points_array:
		spline_points += "[%s]\n" % [point]
		curve.add_point(point[0], point[1], point[2])
	update_multimesh()


func update_spline_points() -> void:
	spline_points = ""
	for i in range(curve.get_point_count()):
		spline_points += "[%s, %s, %s]\n" % [curve.get_point_position(i),
				curve.get_point_in(i), curve.get_point_out(i)]
	property_list_changed_notify()


func _on_curve_changed() -> void:
	update_spline_points()
	update_multimesh()


func create_multimesh() -> void:
	var multimesh_instance := MultiMeshInstance.new()
	add_child(multimesh_instance)
	move_child(multimesh_instance, 0)
	multimesh = MultiMesh.new()
	multimesh_instance.multimesh = multimesh
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh

func update_multimesh() -> void:
	if !multimesh:
		if get_child_count() > 0 and get_child(0) is MultiMeshInstance:
			multimesh = get_child(0).multimesh
		else:
			create_multimesh()
	var curve_length := curve.get_baked_length()
	if spacing >= curve_length:
		multimesh.instance_count = 1
		multimesh.set_instance_transform(0, transform)
	else:
		multimesh.instance_count = int(curve_length / spacing)
		for i in range(multimesh.instance_count):
			multimesh.set_instance_transform(i, Transform(Basis.IDENTITY,
					curve.interpolate_baked(curve_length / multimesh.instance_count * i, true)))
