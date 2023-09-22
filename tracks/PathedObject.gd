@tool
class_name PathedObject
extends Path3D


@export var mesh: Mesh = null :
	set(m):
		mesh = m
		if !get_multimesh():
			create_multimesh()
		multimesh.mesh = mesh
		update_multimesh()
var multimesh: MultiMesh = null
@export_range (0, 10) var spacing := 1.0 :
	set(space):
		spacing = space
		update_multimesh()


func _ready() -> void:
	var _discard := curve_changed.connect(_on_curve_changed)
	if !multimesh:
		create_multimesh()
	update_multimesh()


func get_multimesh() -> MultiMesh:
	for child in get_children():
		if child is MultiMeshInstance3D:
			multimesh = child.multimesh
			break
	return multimesh


func _on_curve_changed() -> void:
	update_multimesh()


func create_multimesh() -> void:
	var multimesh_instance := MultiMeshInstance3D.new()
	add_child(multimesh_instance)
	move_child(multimesh_instance, 0)
	multimesh = MultiMesh.new()
	multimesh_instance.multimesh = multimesh
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh

func update_multimesh() -> void:
	if !multimesh:
		if get_child_count() > 0 and get_child(0) is MultiMeshInstance3D:
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
			multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY,
					curve.sample_baked(curve_length / multimesh.instance_count * i, true)))
