extends Gate
class_name ProceduralGate


var geometry: GeometryInstance3D
var static_body: StaticBody3D
var checkpoint: Checkpoint


func _ready() -> void:
	_add_geometry()

	static_body = StaticBody3D.new()
	add_child(static_body)
	_add_collision()

	checkpoint = Checkpoint.new()
	add_child(checkpoint)
	_add_checkpoint()


func _add_geometry() -> void:
	pass


func _add_collision() -> void:
	pass


func _add_checkpoint() -> void:
	pass
