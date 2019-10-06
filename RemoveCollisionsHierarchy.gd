tool
extends EditorScenePostImport


func post_import(scene):
	if scene == null:
		print("Scene is empty.")
		return
	if scene is Drone:
		for node in scene.get_children():
			if node is MeshInstance:
				var node_name = node.name
				if node_name.ends_with("-colbox"):
					var shape = collision_shape(node, "box")
					shape.name = node_name.replace("-colbox", "-col")
					scene.add_child(shape)
					shape.set_owner(scene)
					node.queue_free()
					continue
				elif node_name.ends_with("-colcylinder"):
					var shape = collision_shape(node, "cylinder")
					shape.name = node_name.replace("-colcylinder", "-col")
					scene.add_child(shape)
					shape.set_owner(scene)
					node.queue_free()
					continue
				for child in node.get_children():
					var child_name = child.name
					if child is StaticBody:
						for coll in child.get_children():
							child.remove_child(coll)
							scene.add_child(coll)
							coll.set_owner(scene)
							coll.transform = child.transform
							coll.name = child_name + "-col"
						child.queue_free()
					elif child is MeshInstance:
						if child_name.ends_with("-colbox"):
							var shape = collision_shape(child, "box")
							shape.name = child_name.replace("-colbox", "-col")
							scene.add_child(shape)
							shape.set_owner(scene)
						elif child_name.ends_with("-colcylinder"):
							var shape = collision_shape(child, "cylinder")
							shape.name = child_name.replace("-colcylinder", "-col")
							scene.add_child(shape)
							shape.set_owner(scene)
						child.queue_free()
	elif scene is Propeller:
		if scene.get_child_count() != 3:
			print("Error: Expected 3 nodes: CW, CCW, -cylinder.")
		var scene_checks = [false, false, false]
		for node in scene.get_children():
			var collision = null
			if node is MeshInstance:
				if node.name == "CW" and scene_checks[0] == false:
					scene_checks[0] = true
				elif node.name == "CCW" and scene_checks[1] == false:
					scene_checks[1] = true
				elif node.name.ends_with("-cylinder") and scene_checks[2] == false:
					scene_checks[2] = true
					collision = node
			if scene_checks == [true, true, true]:
				var area = Area.new()
				scene.add_child(area)
				area.set_owner(scene)
				area.name = "Area"
				var shape = collision_shape(collision, "cylinder")
				area.add_child(shape)
				shape.set_owner(scene)
				shape.name = collision.name.replace("-colcylinder", "-col")
				collision.queue_free()
	elif scene is Motor:
		for node in scene.get_children():
			var node_name = node.name
			if node_name.ends_with("-colcylinder"):
				var area = Area.new()
				scene.add_child(area)
				area.set_owner(scene)
				area.name = "Area"
				var shape = collision_shape(node, "cylinder")
				area.add_child(shape)
				shape.set_owner(scene)
				shape.name = node.name.replace("-colcylinder", "-col")
				node.queue_free()
	
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
		_:
			return
	
	collision.transform = node.transform
	collision.scale = Vector3.ONE
	return collision
