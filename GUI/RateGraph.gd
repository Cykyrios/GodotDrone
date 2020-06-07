extends Control


var pitch: Array = []
var roll: Array = []
var yaw: Array = []
var rate_pitch: int = 667
var rate_roll: int = 667
var rate_yaw: int = 667
var expo_pitch: float = 0.1
var expo_roll: float = 0.1
var expo_yaw: float = 0.1

var num_points: int = 101
var graph_size: int = 256


func _ready():
	update_rates(Vector3(rate_pitch, rate_roll, rate_yaw), Vector3(expo_pitch, expo_roll, expo_yaw))
	update()


func update_rates(rates: Vector3, expos: Vector3):
	rate_pitch = int(rates.x)
	rate_roll = int(rates.y)
	rate_yaw = int(rates.z)
	expo_pitch = expos.x
	expo_roll = expos.y
	expo_yaw = expos.z
	
	var input: float = 0.0
	if pitch.size() != num_points:
		pitch.clear()
		roll.clear()
		yaw.clear()
		for i in range(num_points):
			pitch.append(Vector2(0, 0))
			roll.append(Vector2(0, 0))
			yaw.append(Vector2(0, 0))
	for i in range(num_points):
		input = i / 50.0 - 1
		pitch[i].x = input
		roll[i].x = input
		yaw[i].x = input
		pitch[i].y = ((1 - expo_pitch) * input + expo_pitch * pow(input, 3)) * rate_pitch
		roll[i].y = ((1 - expo_roll) * input + expo_roll * pow(input, 3)) * rate_roll
		yaw[i].y = ((1 - expo_yaw) * input + expo_yaw * pow(input, 3)) * rate_yaw
	
	var max_rate = max(max(rate_pitch, rate_roll), rate_yaw)
	for i in range(num_points):
		pitch[i].x = (pitch[i].x + 1) * graph_size / 2
		roll[i].x = (roll[i].x + 1) * graph_size / 2
		yaw[i].x = (yaw[i].x + 1) * graph_size / 2
		pitch[i].y = (2 - (pitch[i].y / max_rate + 1)) * graph_size / 2
		roll[i].y = (2 - (roll[i].y / max_rate + 1)) * graph_size / 2
		yaw[i].y = (2 - (yaw[i].y / max_rate + 1)) * graph_size / 2
	update()


func _draw():
	# Background
	draw_rect(Rect2(Vector2(0, 0), Vector2(graph_size, graph_size)), Color(0.9, 0.9, 0.9))
	# Center lines
	draw_line(Vector2(0, graph_size / 2), Vector2(graph_size, graph_size / 2), Color(0.4, 0.4, 0.4), 1)
	draw_line(Vector2(graph_size / 2, 0), Vector2(graph_size / 2, graph_size), Color(0.4, 0.4, 0.4), 1)
	# Rates
	draw_polyline(PoolVector2Array(pitch), Color(1, 0, 0, 1), 1.5, true)
	draw_polyline(PoolVector2Array(roll), Color(0, 1, 0, 1), 1.5, true)
	draw_polyline(PoolVector2Array(yaw), Color(0, 0, 1, 1), 1.5, true)
	# Frame
	draw_line(Vector2(0, 0), Vector2(graph_size, 0), Color(0, 0, 0), 2)
	draw_line(Vector2(graph_size, 0), Vector2(graph_size, graph_size), Color(0, 0, 0), 2)
	draw_line(Vector2(graph_size, graph_size), Vector2(0, graph_size), Color(0, 0, 0), 2)
	draw_line(Vector2(0, graph_size), Vector2(0, 0), Color(0, 0, 0), 2)
