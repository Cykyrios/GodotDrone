@tool
extends EditorScenePostImport


func _post_import(scene: Node) -> Object:
	if scene == null:
		print("Scene is empty.")
		return
	var path := get_source_file().get_base_dir()
	for node in scene.get_children():
		var node_name := node.name as String
		node.name = node_name + "_Mesh"
		var sb := StaticBody3D.new()
		scene.add_child(sb)
		sb.set_owner(scene)
		sb.name = node_name
		sb.transform = node.transform
		scene.remove_child(node)
		sb.add_child(node)
		node.set_owner(scene)
		node.transform = Transform3D()
		for child in node.get_children():
			var child_name := child.name as String
			var col: CollisionShape3D = null
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
	for sb in (scene.get_children() as Array[Node3D]):
		for child in sb.get_children():
			child.set_owner(sb)
		var transform := sb.transform
		sb.transform.origin = Vector3(0, transform.origin.y, 0)
		var packed_scene := PackedScene.new()
		if packed_scene.pack(sb) == OK:
			ResourceSaver.save(packed_scene, path + "/" + (sb.name as String) + ".tscn")
		sb.transform = transform
		reset_owner(sb, scene)
	return scene


func collision_shape(node: MeshInstance3D, shape: String) -> CollisionShape3D:
	var collision := CollisionShape3D.new()
	match shape:
		"box":
			var coll_shape := BoxShape3D.new()
			coll_shape.size = node.scale
			collision.shape = coll_shape
		"cylinder":
			var coll_shape := CylinderShape3D.new()
			coll_shape.radius = node.scale.x
			coll_shape.height = node.scale.y * 2.0
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


func reset_owner(node: Node, owner: Node) -> void:
	node.set_owner(owner)
	for child in node.get_children():
		reset_owner(child, owner)
