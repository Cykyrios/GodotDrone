@tool
extends EditorScenePostImport


func _post_import(scene: Node) -> Object:
	if scene == null:
		print("Scene is empty.")
		return
	if scene is StaticBody3D:
		print("Importing %s as StaticBody3D" % [scene.name])
		for node in scene.get_children():
			var node_name := node.name as String
			print("Processing %s" % [node_name])
			if node_name.ends_with("-colbox"):
				var shape := collision_shape(node, "box")
				shape.name = node_name.replace("-colbox", "-col")
				scene.add_child(shape)
				shape.set_owner(scene)
				node.queue_free()
			elif node_name.ends_with("-colcylinder"):
				var shape := collision_shape(node, "cylinder")
				shape.name = node_name.replace("-colcylinder", "-col")
				scene.add_child(shape)
				shape.set_owner(scene)
				node.queue_free()
	print("Imported %s successfully." % [scene.name])
	return scene


func collision_shape(node: Node3D, shape: String) -> CollisionShape3D:
	var collision := CollisionShape3D.new()
	var min_size: float
	match shape:
		"box":
			var coll_shape := BoxShape3D.new()
			coll_shape.size = node.scale
			min_size = coll_shape.size[coll_shape.size.min_axis_index()]
			if min_size < coll_shape.margin:
				coll_shape.margin = min_size
			collision.shape = coll_shape
		"cylinder":
			var coll_shape := CylinderShape3D.new()
			coll_shape.radius = node.scale.x
			coll_shape.height = node.scale.y * 2.0
			min_size = minf(coll_shape.radius, coll_shape.height)
			if min_size < coll_shape.margin:
				coll_shape.margin = min_size
			collision.shape = coll_shape
		"mesh":
			var coll_shape := ConvexPolygonShape3D.new()
			coll_shape.points = node.mesh.get_faces()
			collision.shape = coll_shape
		_:
			return

	collision.transform = node.transform
	collision.scale = Vector3.ONE
	return collision
