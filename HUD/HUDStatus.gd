extends Label


enum Status {DISARMED, ARMED, LAUNCH, TURTLE, RECOVERY}


var status: int = Status.DISARMED setget set_status
var message_timer := Timer.new()


func _ready() -> void:
	add_child(message_timer)
	message_timer.one_shot = true
	var _discard = message_timer.connect("timeout", self, "_on_message_timer_timeout")
	
	set_message("DISARMED")


func set_status(s: int) -> void:
	if s < Status.size():
		status = s
		var status_text := ""
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


func set_message(msg: String = "") -> void:
	text = "\n\n\n\n\n\n\n%s" % msg


func clear_message() -> void:
	set_message()


func _on_message_timer_timeout() -> void:
	clear_message()
	if status == Status.DISARMED:
		set_status(Status.DISARMED)


func _on_armed(mode: int) -> void:
	match mode:
		FlightController.FlightMode.TURTLE:
			self.status = Status.TURTLE
		FlightController.FlightMode.LAUNCH:
			self.status = Status.LAUNCH
		_:
			self.status = Status.ARMED


func _on_disarmed() -> void:
	self.status = Status.DISARMED


func _on_arm_failed(reason: int) -> void:
	var reason_msg := ""
	match reason:
		FlightController.ArmFail.THROTTLE_HIGH:
			reason_msg = "THROTTLE HIGH"
		FlightController.ArmFail.CRASH_RECOVERY_MODE:
			reason_msg = "CRASH RECOVERY MODE"
	set_message("*** %s ***" % reason_msg)
	message_timer.start(1)


func _on_mode_changed(mode: int) -> void:
	if status == Status.DISARMED:
		return
	if mode != FlightController.FlightMode.TURTLE and mode != FlightController.FlightMode.LAUNCH \
			and (status == Status.TURTLE or status == Status.LAUNCH):
		clear_message()
	elif mode == FlightController.FlightMode.AUTO:
		self.status = Status.RECOVERY
	else:
		clear_message()
