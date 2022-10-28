extends Control


var _pitch: Array[Vector2] = []
var _roll: Array[Vector2] = []
var _yaw: Array[Vector2] = []

var color_background := Color(0.2, 0.2, 0.2)
var color_frame := Color(0.8, 0.8, 0.8)
var color_lines := Color(0.5, 0.5, 0.5)
var color_pitch := Color(1.0, 0.2, 0.2)
var color_roll := Color(0.35, 1.0, 0.35)
var color_yaw := Color(0.3, 0.5, 1.0)

var graph_size := 256

var max_rates_label: RichTextLabel = null


func _ready() -> void:
	max_rates_label = RichTextLabel.new()
	add_child(max_rates_label)
	max_rates_label.position = Vector2(10, 10)
	max_rates_label.bbcode_enabled = true
	max_rates_label.clip_contents = false
	max_rates_label.fit_content_height = true
	queue_redraw()


func update_rates(pitch: Array[Vector2], roll: Array[Vector2], yaw: Array[Vector2]) -> void:
	_pitch.clear()
	_roll.clear()
	_yaw.clear()
	_pitch = pitch
	_roll = roll
	_yaw = yaw
	queue_redraw()


func _draw() -> void:
	# Background
	draw_rect(Rect2(Vector2(0, 0), Vector2(graph_size, graph_size)), color_background)
	# Center lines
	draw_line(Vector2(0, graph_size / 2.0), Vector2(graph_size, graph_size / 2.0), color_lines, 1)
	draw_line(Vector2(graph_size / 2.0, 0), Vector2(graph_size / 2.0, graph_size), color_lines, 1)
	# Rates
	var num_points := _pitch.size()
	var max_rate := maxf(maxf(_pitch[-1].y, _roll[-1].y), _yaw[-1].y)
	var get_chart_point := func get_chart_point(point: Vector2) -> Vector2:
		var x := (point.x + 1) * graph_size / 2
		var y := (2 - (point.y / max_rate + 1)) * graph_size / 2
		return Vector2(x, y)
	var pitch: Array[Vector2] = []
	var roll: Array[Vector2] = []
	var yaw: Array[Vector2] = []
	for i in num_points:
		pitch.append(get_chart_point.call(_pitch[i]))
		roll.append(get_chart_point.call(_roll[i]))
		yaw.append(get_chart_point.call(_yaw[i]))
	draw_polyline(PackedVector2Array(pitch), color_pitch, 1.5, true)
	draw_polyline(PackedVector2Array(roll), color_roll, 1.5, true)
	draw_polyline(PackedVector2Array(yaw), color_yaw, 1.5, true)
	# Frame
	draw_line(Vector2(0, 0), Vector2(graph_size, 0), Color(0.8, 0.8, 0.8), 2)
	draw_line(Vector2(graph_size, 0), Vector2(graph_size, graph_size), Color(0.8, 0.8, 0.8), 2)
	draw_line(Vector2(graph_size, graph_size), Vector2(0, graph_size), Color(0.8, 0.8, 0.8), 2)
	draw_line(Vector2(0, graph_size), Vector2(0, 0), color_frame, 2)
	# Max rates
	max_rates_label.text = "[color=#%s]P = %d[/color]\n" % [color_pitch.to_html(false), _pitch[-1].y] \
			+ "[color=#%s]R = %d[/color]\n" % [color_roll.to_html(false), _roll[-1].y] \
			+ "[color=#%s]Y = %d[/color]" % [color_yaw.to_html(false), _yaw[-1].y]
