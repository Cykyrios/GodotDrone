tool
extends EditorScenePostImport


func post_import(scene):
	if scene == null:
		print("Scene is empty.")
		return
	if scene is StaticBody:
		print("Importing %s as StaticBody" % [scene.name])
		for node in scene.get_children():
			var node_name = node.name
			print("Processing %s" % [node_name])
			if node_name.ends_with("-colbox"):
				var shape = collision_shape(node, "box")
				shape.name = node_name.replace("-colbox", "-col")
				scene.add_child(shape)
				shape.set_owner(scene)
				node.queue_free()
			elif node_name.ends_with("-colcylinder"):
				var shape = collision_shape(node, "cylinder")
				shape.name = node_name.replace("-colcylinder", "-col")
				scene.add_child(shape)
				shape.set_owner(scene)
				node.queue_free()
	
	print("Imported %s successfully." % [scene.name])
	return scene


func collision_shape(node : Spatial, shape : String):
	var collision = CollisionShape.new()
	var min_size: float
	match shape:
		"box":
			var collision_shape = BoxShape.new()
			collision_shape.extents = node.scale
			min_size = collision_shape.extents[collision_shape.extents.min_axis()]
			if min_size < collision_shape.margin:
				collision_shape.margin = min_size
			collision.shape = collision_shape
		"cylinder":
			var collision_shape = CylinderShape.new()
			collision_shape.radius = node.scale.x
			collision_shape.height = node.scale.y * 2.0
			min_size = min(collision_shape.radius, collision_shape.height)
			if min_size < collision_shape.margin:
				collision_shape.margin = min_size
			collision.shape = collision_shape
		"mesh":
			var collision_shape = ConvexPolygonShape.new()
			collision_shape.points = node.mesh.get_faces()
			collision.shape = collision_shape
		_:
			return
	
	collision.transform = node.transform
	collision.scale = Vector3.ONE
	return collision
