class_name HUDPosition
extends Control

@onready var x_val := %XValue as Label
@onready var y_val := %YValue as Label
@onready var z_val := %ZValue as Label

func update_position(pos: Vector3) -> void:
	x_val.text = "%5d.%-2d" % [pos.x, (absf(pos.x) - floori(absf(pos.x))) * 100]
	y_val.text = "%5d.%-2d" % [pos.y, (absf(pos.y) - floori(absf(pos.y))) * 100]
	z_val.text = "%5d.%-2d" % [pos.z, (absf(pos.z) - floori(absf(pos.z))) * 100]
