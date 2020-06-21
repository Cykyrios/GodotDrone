extends Node
class_name LapTimer


var time := 0.0
var paused := true


func _physics_process(delta):
	if not paused:
		time += delta


func get_minute_second_decimal():
	var minute := int(time / 60)
	var second := int(time - minute * 60)
	var decimal := int((time - minute * 60 - second) * 1000)
	var dict := {"minute": minute, "second": second, "millisecond": decimal}
	return dict


func reset():
	time = 0.0


func start():
	paused = false


func stop():
	paused = true
