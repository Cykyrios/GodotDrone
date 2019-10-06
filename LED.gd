extends Spatial

var mat = SpatialMaterial.new()
export (Color) var color = Color(0, 0, 0)

var timer = Timer.new()


func _enter_tree():
	$LightMesh.material_override = mat
	mat.albedo_color = Color(0.4, 0.4, 0.4)
	mat.emission_enabled = true
	mat.emission_energy = 1
	mat.emission = color


func _ready():
	add_child(timer)
	timer.connect("timeout", self, "_on_timer_elapsed")


#func _process(delta):
#	pass


func change_color(c : Color = Color(0, 0, 0)):
	mat.emission = c


func set_blink(delay : float = 0.0):
	if delay > 0.0:
		timer.start(delay)
	else:
		timer.stop()
		mat.emission_enabled = true


func _on_timer_elapsed():
	mat.emission_enabled = !mat.emission_enabled
