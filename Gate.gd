tool
extends Spatial
class_name Gate

onready var area = $Area


func _ready():
	area.connect("body_entered", self, "_on_Area_body_entered")
	area.connect("body_exited", self, "_on_Area_body_exited")


func _on_Area_body_entered(body):
	if body is Drone:
		print("entered: ", body.linear_velocity)


func _on_Area_body_exited(body):
	if body is Drone:
		print("exited: ", body.linear_velocity)
