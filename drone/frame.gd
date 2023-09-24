class_name Frame
extends Node3D


var collision_shapes := []


func _ready() -> void:
	update_collision_shapes(self)


func update_collision_shapes(node: Node3D) -> void:
	for child in node.get_children():
		if child is CollisionShape3D:
			collision_shapes.append(child)
		update_collision_shapes(child)
