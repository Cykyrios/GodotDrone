tool
extends Area
class_name LaunchArea


var col: CollisionShape = null
var shape: BoxShape = null
export (Vector3) var area_extents := Vector3(0.1, 0.05, 0.05) setget set_area_extents


func _ready() -> void:
	col = get_collision_shape()
	update_collision_shape()


func get_collision_shape() -> Node:
	if get_child_count() == 0:
		col = CollisionShape.new()
		col.shape = BoxShape.new()
		col.shape.extents = area_extents
		add_child(col)
		col.owner = self
	return get_child(0)


func set_area_extents(extents: Vector3) -> void:
	if not is_inside_tree():
		yield(self, "ready")
	extents.x = abs(extents.x)
	extents.y = abs(extents.y)
	extents.z = abs(extents.z)
	area_extents = extents
	col = get_collision_shape()
	update_collision_shape()


func update_collision_shape() -> void:
	col.shape.extents = area_extents
	col.transform = Transform.IDENTITY
	col.translate_object_local(Vector3.UP * col.shape.extents.y)
	col.translate_object_local(Vector3.BACK * col.shape.extents.z)
