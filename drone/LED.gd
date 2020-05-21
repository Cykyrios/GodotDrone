extends Spatial

var mat = SpatialMaterial.new()
export (Color) var color = Color(0, 0, 0)

var timer = Timer.new()
# blink_pattern is an array of Vector2 containing on and off durations
var blink_pattern = [] setget set_blink_pattern
var pattern_idx = -1


func _enter_tree():
	$LightMesh.material_override = mat
	mat.albedo_color = Color(0.4, 0.4, 0.4)
	mat.emission_enabled = true
	mat.emission_energy = 1
	mat.emission = color


func _ready():
	add_child(timer)
	timer.connect("timeout", self, "_on_timer_elapsed")


#func _process(delta):
#	pass


func change_color(c : Color = Color(0, 0, 0)):
	mat.emission = c


func set_blink_pattern(pattern: Array = []):
	if pattern.empty():
		timer.stop()
		mat.emission_enabled = true
	else:
		var pattern_is_valid = true
		for vec in pattern:
			if not vec is Vector2:
				pattern_is_valid = false
				break
		if not pattern_is_valid:
			set_blink_pattern()
		else:
			blink_pattern = pattern
			pattern_idx = -1
			update_blink()


func update_blink():
	pattern_idx += 1
	if pattern_idx >= blink_pattern.size():
		pattern_idx = 0
	var delay = blink_pattern[pattern_idx].x
	if delay > 0:
		mat.emission_enabled = true
		timer.start(delay)
	else:
		delay = blink_pattern[pattern_idx].y
		if delay > 0:
			mat.emission_enabled = false
			timer.start(delay)
		else:
			update_blink()


func _on_timer_elapsed():
	if mat.emission_enabled:
		mat.emission_enabled = false
		timer.start(blink_pattern[pattern_idx].y)
	else:
		update_blink()
