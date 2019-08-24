extends Camera

export(NodePath) var target = null
export(float, 0.1, 10.0) var target_distance = 2.0
export(Vector3) var target_offset = Vector3.ZERO
export(Vector3) var camera_offset = Vector3.ZERO
export(float, 0, 1) var offset_weight = 0

var target_node


func _ready():
	if target:
		target_node = get_node(target)


func _process(delta):
	if target_node is Spatial:
		var target_pos = target_node.global_transform.origin + target_offset
		var pos_diff = target_pos - global_transform.origin
		var offset = target_node.global_transform.xform(camera_offset)
		var new_pos = target_pos - pos_diff.normalized() * target_distance
		new_pos = new_pos.linear_interpolate(offset, offset_weight)
		look_at_from_position(new_pos, target_pos, Vector3.UP)
