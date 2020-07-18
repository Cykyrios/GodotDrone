extends Spatial
class_name Frame


var collision_shapes := []


func _ready() -> void:
	update_collision_shapes(self)


func update_collision_shapes(node: Spatial) -> void:
	for child in node.get_children():
		if child is CollisionShape:
			collision_shapes.append(child)
		update_collision_shapes(child)
