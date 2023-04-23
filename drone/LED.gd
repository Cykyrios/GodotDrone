class_name ModeLED
extends Node3D


var mat := StandardMaterial3D.new()
@export var color := Color(0, 0, 0)

var timer := Timer.new()
# blink_pattern is an array of Vector2 containing checked and unchecked durations
var blink_pattern := [] :
	get:
		return blink_pattern # TODOConverter40 Non existent get function
	set(pattern):
		if pattern.is_empty():
			timer.stop()
			mat.emission_enabled = true
		else:
			var pattern_is_valid := true
			for vec in pattern:
				if not vec is Vector2:
					pattern_is_valid = false
					break
			if not pattern_is_valid:
				blink_pattern = []
			else:
				blink_pattern = pattern
				pattern_idx = -1
				update_blink()
var pattern_idx := -1


func _enter_tree() -> void:
	$LightMesh.material_override = mat
	mat.albedo_color = Color(0.4, 0.4, 0.4)
	mat.emission_enabled = true
	mat.emission_energy = 1
	mat.emission = color


func _ready() -> void:
	add_child(timer)
	var _discard = timer.timeout.connect(_on_timer_elapsed)


func change_color(c: Color = Color(0, 0, 0)) -> void:
	mat.emission = c


func update_blink() -> void:
	pattern_idx += 1
	if pattern_idx >= blink_pattern.size():
		pattern_idx = 0
	var delay: float = blink_pattern[pattern_idx].x
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


func _on_timer_elapsed() -> void:
	if mat.emission_enabled:
		mat.emission_enabled = false
		timer.start(blink_pattern[pattern_idx].y)
	else:
		update_blink()
