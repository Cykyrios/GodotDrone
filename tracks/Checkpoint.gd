tool
extends Area
class_name Checkpoint


signal entered
signal exited
signal passed


var bodies := []
var areas_per_body := []

export (bool) var backward := false setget set_backward
var active := false
var selected := false setget set_selected
var area_visible := false setget set_area_visible
var mat := ShaderMaterial.new()

var drone_raycasts := []


func _ready() -> void:
	var shad := load("res://tracks/CheckpointShader.tres")
	mat.shader = shad
	
	var _discard = connect("body_entered", self, "_on_entered")
	_discard = connect("body_exited", self, "_on_exited")
	
	for col in get_children():
		if col is CollisionShape:
			var m := MeshInstance.new()
			m.transform = col.transform
			if col.shape is BoxShape:
					m.mesh = CubeMesh.new()
					m.mesh.size = (col.shape as BoxShape).extents * 2
			elif col.shape is CylinderShape:
					m.mesh = CylinderMesh.new()
					var s := col.shape as CylinderShape
					m.mesh.top_radius = s.radius
					m.mesh.bottom_radius = s.radius
					m.mesh.height = s.height
			m.mesh.surface_set_material(0, mat)
			m.visible = false
			add_child(m)
			m.set_owner(self)
	set_area_visible(true)


func _process(_delta: float) -> void:
	if Engine.editor_hint or active:
		mat.set_shader_param("CheckpointPosition", global_transform.origin)
		mat.set_shader_param("CheckpointForward", global_transform.basis.z)


func _physics_process(_delta: float) -> void:
	if not drone_raycasts.empty():
		var entry_direction := global_transform.basis.z
		if backward:
			entry_direction = -entry_direction
		for drone in drone_raycasts:
			var pos_dot: float = (drone.global_transform.origin -
					global_transform.origin).dot(entry_direction)
			var vel_dot: float = drone.linear_velocity.dot(entry_direction)
			if vel_dot < 0:
				if pos_dot < 0 or backward and pos_dot > 0:
					drone_raycasts.erase(drone)
					if active:
						emit_signal("passed", self)
					else:
						emit_signal("exited")
			else:
				drone_raycasts.erase(drone)


func set_backward(back: bool) -> void:
	backward = back
	mat.set_shader_param("CheckpointBackward", backward)


func set_active(act: bool) -> void:
	active = act
	set_area_visible(active)


func set_selected(select: bool) -> void:
	selected = select
	mat.set_shader_param("Selected", selected)


func set_area_visible(vis: bool) -> void:
	for c in get_children():
		if c is MeshInstance:
			c.visible = vis


func get_velocity_check(body: Node) -> float:
	var dot_product: float = body.linear_velocity.dot(global_transform.basis.xform(Vector3.FORWARD))
	return dot_product


func _on_entered(body: Node) -> void:
	if body is Drone:
		var dot_product := get_velocity_check(body)
		if !backward and dot_product > 0.0 or backward and dot_product < 0.0:
			if body in bodies:
				var i := bodies.bsearch(body)
				areas_per_body[i] = areas_per_body[i] + 1
			else:
				bodies.append(body)
				areas_per_body.append(1)
			emit_signal("entered")


func _on_exited(body: Node) -> void:
	if body is Drone and bodies.size() > 0:
		var i := bodies.bsearch(body)
		areas_per_body[i] = areas_per_body[i] - 1
		if areas_per_body[i] == 0:
			areas_per_body.remove(i)
			bodies.remove(i)
			
			var dot_product := get_velocity_check(body)
			if active and (!backward and dot_product > 0.0 or backward and dot_product < 0.0):
				emit_signal("passed", self)
			else:
				emit_signal("exited")


func _on_drone_raycast_hit(drone: Drone) -> void:
	var dot_product := (drone.global_transform.origin - global_transform.origin).dot(global_transform.basis.z)
	if dot_product > 0 or backward and dot_product < 0:
		if not drone_raycasts.has(drone):
			drone_raycasts.append(drone)
