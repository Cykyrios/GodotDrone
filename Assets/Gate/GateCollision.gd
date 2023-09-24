extends StaticBody3D


@onready var shape := $CollisionShape1 as CollisionShape3D


func _ready() -> void:
	var num := 32
	for i in num:
		var s := shape.duplicate() as CollisionShape3D
		add_child(s)
		s.translate_object_local(Vector3(-6.25, 0, 0))
		s.rotate_y(2 * PI * i / num)
		s.translate_object_local(Vector3(6.25, 0, 0))
