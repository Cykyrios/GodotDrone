@tool
extends EditorScenePostImport


func _post_import(scene: Node) -> Object:
	if scene == null:
		print("Scene is empty.")
		return
	if scene is Frame:
		for node in (scene.get_children() as Array[Node]):
			if node is MeshInstance3D:
				var node_name := node.name as String
				if node_name.ends_with("-colbox"):
					var shape := collision_shape(node, "box")
					shape.name = node_name.replace("-colbox", "-col")
					scene.add_child(shape)
					shape.set_owner(scene)
					node.queue_free()
					continue
				elif node_name.ends_with("-colcylinder"):
					var shape := collision_shape(node, "cylinder")
					shape.name = node_name.replace("-colcylinder", "-col")
					scene.add_child(shape)
					shape.set_owner(scene)
					node.queue_free()
					continue
				for child in node.get_children():
					var child_name := child.name as String
					if child is StaticBody3D:
						for coll in child.get_children():
							child.remove_child(coll)
							scene.add_child(coll)
							coll.set_owner(scene)
							coll.transform = child.transform
							coll.name = child_name + "-col"
						child.queue_free()
					elif child is MeshInstance3D:
						if child_name.ends_with("-colbox"):
							var shape := collision_shape(child, "box")
							shape.name = child_name.replace("-colbox", "-col")
							scene.add_child(shape)
							shape.set_owner(scene)
						elif child_name.ends_with("-colcylinder"):
							var shape := collision_shape(child, "cylinder")
							shape.name = child_name.replace("-colcylinder", "-col")
							scene.add_child(shape)
							shape.set_owner(scene)
						child.queue_free()

	elif scene is Propeller:
		if scene.get_child_count() != 4:
			print("Error: Expected 4 nodes: CW, CCW, PropDisk-cylinder, PropBlurDisk.")
			return scene
		var scene_checks := [false, false, false]
		var children := scene.get_children() as Array[Node]
		for node in children:
			var node_name := node.name as String
			var collision_mesh: MeshInstance3D = null
			if node is MeshInstance3D:
				if node_name == "CW" and scene_checks[0] == false:
					scene_checks[0] = true
				elif node_name == "CCW" and scene_checks[1] == false:
					scene_checks[1] = true
				elif node_name.ends_with("-cylinder") and scene_checks[2] == false:
					scene_checks[2] = true
					collision_mesh = node
					var area := Area3D.new()
					scene.add_child(area)
					area.set_owner(scene)
					area.name = "Area3D"
					var shape := collision_shape(collision_mesh, "cylinder")
					area.add_child(shape)
					shape.set_owner(scene)
					shape.name = (collision_mesh.name as String).replace("-colcylinder", "-col")
					collision_mesh.queue_free()
				else:
					# PropBlurDisk
					var mat := node.mesh.surface_get_material(0) as StandardMaterial3D
					mat.flags_transparent = true
					var disk_shader := load("res://drone/parts/propellers/prop_blur_shader.tres") as Shader
					var disk_mat := ShaderMaterial.new()
					disk_mat.shader = disk_shader
					var blur_texture := mat.albedo_texture
					disk_mat.set_shader_parameter("prop_blur", blur_texture)
					disk_mat.set_shader_parameter("alpha_boost", 1)
					node.mesh.surface_set_material(0, disk_mat)
		var prop_shader := load("res://drone/parts/propellers/propeller_shader.tres") as Shader
		var prop_mat := ShaderMaterial.new()
		prop_mat.shader = prop_shader
		for i in 2:
			children[i].mesh.surface_set_material(0, prop_mat)

		if scene_checks != [true, true, true]:
			print("Error reading scene %s" % [scene])
			return scene

		var raycast := RayCast3D.new()
		raycast.name = "RayCast3D"
		raycast.target_position = Vector3.DOWN
		raycast.exclude_parent = true
		scene.add_child(raycast)
		raycast.set_owner(scene)

	elif scene is Motor:
		for node in scene.get_children():
			var node_name := node.name as String
			if node_name.ends_with("-colcylinder"):
				var area := Area3D.new()
				scene.add_child(area)
				area.set_owner(scene)
				area.name = "Area3D"
				var shape := collision_shape(node, "cylinder")
				area.add_child(shape)
				shape.set_owner(scene)
				shape.name = node_name.replace("-colcylinder", "-col")
				node.queue_free()

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
