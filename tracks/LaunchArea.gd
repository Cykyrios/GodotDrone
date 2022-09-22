@tool
extends Area3D
class_name LaunchArea


var col: CollisionShape3D = null
var shape: BoxShape3D = null
@export var area_extents := Vector3(0.1, 0.05, 0.05) :
	set(extents):
		if not is_inside_tree():
			await self.ready
		extents.x = absf(extents.x)
		extents.y = absf(extents.y)
		extents.z = absf(extents.z)
		area_extents = extents
		col = get_collision_shape()
		update_collision_shape()


func _ready() -> void:
	col = get_collision_shape()
	update_collision_shape()


func get_collision_shape() -> Node:
	if get_child_count() == 0:
		col = CollisionShape3D.new()
		col.shape = BoxShape3D.new()
		col.shape.extents = area_extents
		add_child(col)
		col.owner = self
	return get_child(0)


func update_collision_shape() -> void:
	col.shape.extents = area_extents
	col.transform = Transform3D.IDENTITY
	col.translate_object_local(Vector3.UP * col.shape.extents.y)
	col.translate_object_local(Vector3.BACK * col.shape.extents.z)
