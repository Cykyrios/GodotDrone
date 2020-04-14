tool
extends Area
class_name Checkpoint


var bodies = []
var areas_per_body = []

export (bool) var backward = false setget set_backward
var active = false
var selected = false setget set_selected
var area_visible = false setget set_area_visible
var mat = ShaderMaterial.new()

signal entered
signal exited
signal passed


func _ready():
	var shad = load("res://CheckpointShader.tres")
	mat.shader = shad
	
	connect("body_entered", self, "_on_entered")
	connect("body_exited", self, "_on_exited")
	
	for col in get_children():
		if col is CollisionShape:
			var m = MeshInstance.new()
			m.transform = col.transform
			if col.shape is BoxShape:
					m.mesh = CubeMesh.new()
					m.mesh.size = (col.shape as BoxShape).extents * 2
			elif col.shape is CylinderShape:
					m.mesh = CylinderMesh.new()
					var s = col.shape as CylinderShape
					m.mesh.top_radius = s.radius
					m.mesh.bottom_radius = s.radius
					m.mesh.height = s.height
			m.mesh.surface_set_material(0, mat)
			m.visible = false
			add_child(m)
			m.set_owner(self)
	set_area_visible(true)


func _process(delta):
	if Engine.editor_hint or active:
		mat.set_shader_param("CheckpointPosition", global_transform.origin)
		mat.set_shader_param("CheckpointForward", global_transform.basis.z)


func set_backward(back : bool):
	backward = back
	mat.set_shader_param("CheckpointBackward", backward)


func set_active(act : bool):
	active = act
	set_area_visible(active)


func set_selected(select : bool):
	selected = select
	mat.set_shader_param("Selected", selected)


func set_area_visible(vis : bool):
	for c in get_children():
		if c is MeshInstance:
			c.visible = vis


func get_velocity_check(body):
	var dot_product = body.linear_velocity.dot(global_transform.basis.xform(Vector3.FORWARD))
	return dot_product


func _on_entered(body):
	if body is Drone:
		var dot_product = get_velocity_check(body)
		if !backward and dot_product > 0.0 or backward and dot_product < 0.0:
			if body in bodies:
				var i = bodies.bsearch(body)
				areas_per_body[i] = areas_per_body[i] + 1
			else:
				bodies.append(body)
				areas_per_body.append(1)
			emit_signal("entered")


func _on_exited(body):
	if body is Drone and bodies.size() > 0:
		var i = bodies.bsearch(body)
		areas_per_body[i] = areas_per_body[i] - 1
		if areas_per_body[i] == 0:
			areas_per_body.remove(i)
			bodies.remove(i)
			
			var dot_product = get_velocity_check(body)
			if active and (!backward and dot_product > 0.0 or backward and dot_product < 0.0):
				emit_signal("passed", self)
			else:
				emit_signal("exited")
