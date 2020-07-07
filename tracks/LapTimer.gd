extends Node
class_name LapTimer


var time := 0.0
var paused := true


func _physics_process(delta):
	if not paused:
		time += delta


func get_minute_second_decimal(t: float = -1.0) -> Dictionary:
	if t < 0:
		t = time
	var minute := int(t / 60)
	var second := int(t - minute * 60)
	var decimal := int((t - minute * 60 - second) * 100)
	var dict := {"minute": minute, "second": second, "decimal": decimal}
	return dict


func get_time_string(t: float = -1.0):
	var time_dict := get_minute_second_decimal(t)
	var text := "%02d:%02d.%02d" % [time_dict["minute"], time_dict["second"], time_dict["decimal"]]
	return text


func reset():
	time = 0.0


func start():
	paused = false


func stop():
	paused = true
