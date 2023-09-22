class_name HUDStatus
extends Label


enum Status {DISARMED, ARMED, LAUNCH, TURTLE, RECOVERY}


var status := Status.DISARMED:
	set(s):
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
var message_timer := Timer.new()


func _ready() -> void:
	add_child(message_timer)
	message_timer.one_shot = true
	var _discard = message_timer.timeout.connect(_on_message_timer_timeout)

	set_message("DISARMED")


func set_message(msg: String = "") -> void:
	text = "\n\n\n\n\n\n\n%s" % [msg]


func clear_message() -> void:
	set_message()


func _on_message_timer_timeout() -> void:
	clear_message()
	if status == Status.DISARMED:
		status = Status.DISARMED


func _on_armed(mode: FlightMode) -> void:
	match mode:
		FlightMode.Type.TURTLE:
			self.status = Status.TURTLE
		FlightMode.Type.LAUNCH:
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
	set_message("*** %s ***" % [reason_msg])
	message_timer.start(1)


func _on_mode_changed(mode: FlightMode) -> void:
	if status == Status.DISARMED:
		return
	if not mode is FlightModeTurtle and not mode is FlightModeLaunch \
			and (status == Status.TURTLE or status == Status.LAUNCH):
		clear_message()
	elif mode is FlightModeRecover:
		self.status = Status.RECOVERY
	else:
		clear_message()
