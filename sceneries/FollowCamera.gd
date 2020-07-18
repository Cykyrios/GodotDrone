extends Camera


export(NodePath) var target = null
export(float, 0.1, 10.0) var target_distance := 2.0
export(Vector3) var target_offset := Vector3.ZERO
export(Vector3) var camera_offset := Vector3.ZERO
export(float, 0, 100) var speed := 0.0

var target_node = null


func _ready() -> void:
	if target:
		target_node = get_node(target)


func _physics_process(delta: float) -> void:
	if target_node is Spatial:
		var target_pos: Vector3 = target_node.global_transform.origin + target_offset
		var pos_diff := target_pos - global_transform.origin
		var target_forward: Vector3 = -target_node.global_transform.basis.z
		target_forward = Vector3(target_forward.x, 0, target_forward.z)
		var offset := Vector3(camera_offset.x, 0, camera_offset.z)
		var cross_prod := offset.normalized().cross(target_forward.normalized()).y
		var angle := asin(cross_prod)
		if camera_offset.dot(target_forward) >= 0:
			angle = PI + angle
		else:
			angle = -angle
		offset = target_pos + camera_offset.rotated(Vector3.UP, angle)
		var new_pos := target_pos - pos_diff.normalized() * target_distance
		new_pos = new_pos.linear_interpolate(offset, speed * delta)
		look_at_from_position(new_pos, target_pos, Vector3.UP)
