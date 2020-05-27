tool
extends EditorScenePostImport


func post_import(scene):
	if scene == null:
		print("Scene is empty.")
		return
	var path = get_source_folder()
	for node in scene.get_children():
		var node_name = node.name
		node.name += "_Mesh"
		var sb = StaticBody.new()
		scene.add_child(sb)
		sb.set_owner(scene)
		sb.name = node_name
		sb.transform = node.transform
		scene.remove_child(node)
		sb.add_child(node)
		node.set_owner(scene)
		node.transform = Transform()
		for child in node.get_children():
			var child_name = child.name
			var col
			if child_name.find("-colbox") != -1:
				child_name = child_name.replace("-colbox", "-col")
				col = collision_shape(child, "box")
			elif child_name.find("-colcylinder") != -1:
				child_name = child_name.replace("-colcylinder", "-col")
				col = collision_shape(child, "cylinder")
			elif child_name.find("-colmesh") != -1:
				col = collision_shape(child, "mesh")
			child.free()
			sb.add_child(col)
			col.set_owner(scene)
			col.name = child_name
			continue
	for sb in scene.get_children():
		for child in sb.get_children():
			child.set_owner(sb)
		var transform = sb.transform
		sb.transform.origin = Vector3(0, transform.origin.y, 0)
		var packed_scene = PackedScene.new()
		if packed_scene.pack(sb) == OK:
			ResourceSaver.save(path + "/" + sb.name + ".tscn", packed_scene)
		sb.transform = transform
		reset_owner(sb, scene)
	
	return scene


func collision_shape(node : MeshInstance, shape : String):
	var collision = CollisionShape.new()
	match shape:
		"box":
			var collision_shape = BoxShape.new()
			collision_shape.extents = node.scale
			collision.shape = collision_shape
		"cylinder":
			var collision_shape = CylinderShape.new()
			collision_shape.radius = node.scale.x
			collision_shape.height = node.scale.y * 2.0
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


func reset_owner(node : Node, owner : Node):
	node.set_owner(owner)
	for child in node.get_children():
		reset_owner(child, owner)
