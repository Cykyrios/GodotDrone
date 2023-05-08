@tool
class_name Motor
extends Node3D


@onready var propeller := get_children().back() as Propeller

@export var clockwise := true :
	set(cw):
		clockwise = cw
		if propeller:
			propeller.clockwise = clockwise
@export_range (0.0, 10000.0) var MAX_TORQUE := 1000.0
@export_range (0.0, 30000.0) var MAX_RPM := 10000.0
@export_range (0, 200000) var RPM_ACCELERATION := 16000.0
@export_range (0, 100) var MIN_POWER := 1
@export_range (100, 20000) var kv := 2000
@export_range (101, 9999) var motor_size := 2207

var torque := 0.0 :
	get:
		if clockwise:
			return torque
		else:
			return -torque
var rpm := 0.0 :
	set(x):
		rpm = clampf(x, -MAX_RPM, MAX_RPM)
		propeller.rpm = rpm
var rpm_target := 0.0
var max_rpm_change := 0.0
var powered := false

@onready var rotor := $Motor_Rotor

var sounds := []
var sound1: AudioStreamPlayer = null
var sound2: AudioStreamPlayer = null
var sound_selector := -1


func _ready() -> void:
	clockwise = clockwise

	if Engine.is_editor_hint():
		return

	MAX_TORQUE = MAX_TORQUE / 1000.0
	max_rpm_change = MAX_TORQUE * RPM_ACCELERATION

	for _i in range(8):
		sounds.append(AudioStreamPlayer.new())
		add_child(sounds[-1])
	sound1 = sounds[0]
	sound2 = sounds[1]
	sounds[0].stream = load("res://Assets/Audio/SFX/Propellers/idle.wav")
	sounds[1].stream = load("res://Assets/Audio/SFX/Propellers/motor1.wav")
	sounds[2].stream = load("res://Assets/Audio/SFX/Propellers/motor2.wav")
	sounds[3].stream = load("res://Assets/Audio/SFX/Propellers/motor3.wav")
	sounds[4].stream = load("res://Assets/Audio/SFX/Propellers/motor4.wav")
	sounds[5].stream = load("res://Assets/Audio/SFX/Propellers/motor5.wav")
	sounds[6].stream = load("res://Assets/Audio/SFX/Propellers/motor6.wav")
	sounds[7].stream = load("res://Assets/Audio/SFX/Propellers/motor7.wav")


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	var rot := rpm * PI / 30.0
	if clockwise:
		rot = -rot
	rotor.rotate_object_local(Vector3.UP, rot * delta)
	propeller.rotate_object_local(Vector3.UP, rot * delta)

	rotor.transform = rotor.transform.orthonormalized()
	propeller.transform = propeller.transform.orthonormalized()


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	var abs_rpm := absf(rpm)
	update_sound(abs_rpm)


func update_thrust(delta: float) -> void:
	var rpm_clamp := max_rpm_change * delta
	if powered:
		rpm = clampf(rpm_target, rpm - rpm_clamp, rpm + rpm_clamp)
		torque = rpm / (MAX_RPM as float) * MAX_TORQUE
	else:
		rpm_clamp = absf(sign(rpm) * max_rpm_change * absf(rpm) / 10000 * delta)
		rpm = clampf(0, rpm - rpm_clamp, rpm + rpm_clamp)
		torque = 0.0


func set_pwm(p: float) -> void:
	rpm_target = p * MAX_RPM


func _on_armed(_mode: int) -> void:
	sound1 = sounds[0]
	sound2 = sounds[1]
	for player in sounds:
		player.volume_db = -80
		player.play()


func update_sound(abs_rpm: float = 0.0) -> void:
	var rpm_ratio: float = abs_rpm / MAX_RPM
	var ratio_range: Array = get_rpm_ratio_range()
	var pitch_range: Array = get_pitch_range()

	if abs_rpm < 10:
		update_sound_source(0)
	elif rpm_ratio < 0.15:
		update_sound_source(1)
		adjust_sound_level(0.05, 0.1, rpm_ratio)
		ratio_range = get_rpm_ratio_range(0, 0.15)
		pitch_range = get_pitch_range(1, 1, 0.85, 1)
	elif rpm_ratio < 0.3:
		update_sound_source(2)
		adjust_sound_level(0.2, 0.3, rpm_ratio)
		ratio_range = get_rpm_ratio_range(0.15, 0.3)
		pitch_range = get_pitch_range(1, 1.15, 0.73, 1)
	elif rpm_ratio < 0.45:
		update_sound_source(3)
		adjust_sound_level(0.35, 0.45, rpm_ratio)
		ratio_range = get_rpm_ratio_range(0.3, 0.45)
		pitch_range = get_pitch_range(1, 1.25, 0.8, 1)
	elif rpm_ratio < 0.6:
		update_sound_source(4)
		adjust_sound_level(0.5, 0.55, rpm_ratio)
		ratio_range = get_rpm_ratio_range(0.45, 0.6)
		pitch_range = get_pitch_range(1, 1.22, 0.81, 1)
	elif rpm_ratio < 0.75:
		update_sound_source(5)
		adjust_sound_level(0.65, 0.7, rpm_ratio)
		ratio_range = get_rpm_ratio_range(0.6, 0.75)
		pitch_range = get_pitch_range(1, 1.23, 0.8, 1)
	elif rpm_ratio < 0.9:
		update_sound_source(6)
		adjust_sound_level(0.8, 0.9, rpm_ratio)
		ratio_range = get_rpm_ratio_range(0.75, 0.9)
		pitch_range = get_pitch_range(1, 1.22, 0.82, 1)
	else:
		update_sound_source(7)
		adjust_sound_level(0.9, 0.95, rpm_ratio)
		ratio_range = get_rpm_ratio_range(0.9, 1)
		pitch_range = get_pitch_range(1, 1.1, 0.91, 1)
	var range_start: float = ratio_range[0]
	var range_end: float = ratio_range[1]
	var pitch1_low: float = pitch_range[0]
	var pitch1_high: float = pitch_range[1]
	var pitch2_low: float = pitch_range[2]
	var pitch2_high: float = pitch_range[3]
	sound1.pitch_scale = lerp(pitch1_low, pitch1_high,
			1 - (range_end - rpm_ratio) / (range_end - range_start))
	sound2.pitch_scale = lerp(pitch2_low, pitch2_high,
			1 - (range_end - rpm_ratio) / (range_end - range_start))
	if sound_selector == 0:
		sound1.volume_db = -80
		sound2.volume_db = -80
	var idle_rpm := MIN_POWER / 100.0 * MAX_RPM
	if absf(rpm) < idle_rpm:
		sound1.volume_db -= 80 * (1 - absf(rpm) / idle_rpm)
		sound2.volume_db -= 80 * (1 - absf(rpm) / idle_rpm)


func update_sound_source(source: int = 0) -> void:
	if source != sound_selector:
		if source == 0:
			for player in sounds:
				player.stop()
		elif sound_selector == 0:
			for player in sounds:
				player.play()
		sound_selector = source
		if sound_selector == 0:
			sound1 = sounds[sound_selector]
			sound2 = sounds[sound_selector]
		else:
			sound1.volume_db = -80
			sound2.volume_db = -80
			sound1 = sounds[sound_selector - 1]
			sound2 = sounds[sound_selector]
		sound1.volume_db = -80
		sound2.volume_db = -80


func adjust_sound_level(b: float, e: float, v: float) -> void:
	var v1 := 0.0
	var v2 := -80.0
	if v <= b:
		sound1.volume_db = v1
		sound2.volume_db = v2
	elif v >= e:
		sound1.volume_db = v2
		sound2.volume_db = v1
	else:
		var v_interp := (v - b) / (e - b)
		sound1.volume_db = get_interpolated_sound_level(v1, v2, v_interp, "expo")
		sound2.volume_db = get_interpolated_sound_level(v1, v2, 1 - v_interp, "expo")


func get_interpolated_sound_level(b: float, e: float, v: float, transition: String = "expo") -> float:
	var result := 0.0
	match transition:
		"expo":
			result = e * pow(2, 10 * (v - 1)) + b - e * 0.001
		"linear":
			result = b + v * (e - b)
	return result


func get_rpm_ratio_range(start: float = 0.0, end: float = 1.0) -> Array:
	return [start, end]


func get_pitch_range(
		start1: float = 1.0, end1: float = 1.0,
		start2: float = 1.0, end2: float = 1.0
) -> Array:
	return [start1, end1, start2, end2]
