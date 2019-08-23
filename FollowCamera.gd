extends Camera

export(NodePath) var target = null
export(float, 0.1, 10.0) var target_distance = 2.0
export(Vector3) var target_offset = Vector3.ZERO

var target_node


func _ready():
	if target:
		target_node = get_node(target)


func _process(delta):
	if target_node is Spatial:
		var target_pos = target_node.global_transform.xform(target_offset)
		var pos_diff = target_pos - global_transform.origin
		var offset = pos_diff.normalized() * target_distance
		look_at_from_position(target_pos - offset, target_pos, Vector3.UP)
