extends Label


enum Status {DISARMED, ARMED, LAUNCH, TURTLE, RECOVERY}


var status: int = Status.DISARMED setget set_status
var message_timer: Timer = Timer.new()


func _ready():
	add_child(message_timer)
	message_timer.one_shot = true
	message_timer.connect("timeout", self, "_on_message_timer_timeout")
	
	set_message("DISARMED")


func set_status(s: int):
	if s < Status.size():
		status = s
		var status_text: String = ""
		match status:
			Status.DISARMED:
				status_text = "DISARMED"
			Status.ARMED:
				status_text = "ARMED"
				message_timer.start(1.0)
			Status.LAUNCH:
				status_text = "LAUNCH CONTROL"
			Status.TURTLE:
				status_text = "TURTLE MODE"
			Status.RECOVERY:
				status_text = "CRASH RECOVERY"
		if status != Status.ARMED and not message_timer.is_stopped():
			message_timer.stop()
		set_message(status_text)


func set_message(msg: String = ""):
	text = "\n\n\n\n\n%s" % msg


func clear_message():
	set_message()


func _on_message_timer_timeout():
	clear_message()


func _on_armed(mode: int):
	match mode:
		FlightController.FlightMode.TURTLE:
			self.status = Status.TURTLE
		FlightController.FlightMode.LAUNCH:
			self.status = Status.LAUNCH
		_:
			self.status = Status.ARMED


func _on_disarmed():
	self.status = Status.DISARMED


func _on_mode_changed(mode: int):
	if status == Status.DISARMED:
		return
	if mode != FlightController.FlightMode.TURTLE and mode != FlightController.FlightMode.LAUNCH \
			and (status == Status.TURTLE or status == Status.LAUNCH):
		clear_message()
	elif mode == FlightController.FlightMode.AUTO:
		self.status = Status.RECOVERY
	else:
		clear_message()
