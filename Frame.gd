extends Spatial
class_name Frame


var collision_shapes = []


func _ready():
	get_collision_shapes(self)


func get_collision_shapes(node : Spatial):
	for child in node.get_children():
		if child is CollisionShape:
			collision_shapes.append(child)
		get_collision_shapes(child)
