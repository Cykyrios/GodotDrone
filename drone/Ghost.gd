extends Spatial
class_name Ghost


enum State {STANDBY, PLAYING}
enum Type {PREVIOUS, RACE, LAP}


var replay_path := ""
var replay := []
var type: int = Type.PREVIOUS
var state: int = State.STANDBY
var frame := 0


func _ready() -> void:
	visible = false


func _physics_process(_delta: float) -> void:
	if state == State.PLAYING:
		frame += 1
		update_transform()


func add_meshes(node: Node) -> void:
	for child in node.get_children():
		add_meshes(child)
		if child is MeshInstance:
			if child.name != "CW" and child.name != "CCW":
				var xform := get_mesh_transform(child)
				add_child(child.duplicate(0))
				get_child(get_child_count() - 1).transform = xform


func get_mesh_transform(node: Node) -> Transform:
	var xform: Transform = node.transform
	if not node.get_parent() is Drone:
		xform *= get_mesh_transform(node.get_parent())
	return xform


func update_drone_model(path: String) -> void:
	var drone_packed: PackedScene = load(path)
	if drone_packed.can_instance():
		var drone: Drone = drone_packed.instance()
		add_meshes(drone)
		drone.queue_free()
		
		var mat := SpatialMaterial.new()
		mat.params_cull_mode = SpatialMaterial.CULL_DISABLED
		mat.albedo_color = Color(0.7, 0.7, 0.7, 0.3)
		mat.distance_fade_mode = SpatialMaterial.DISTANCE_FADE_PIXEL_DITHER
		mat.distance_fade_max_distance = 1.0
		mat.distance_fade_min_distance = 0.2
		match type:
			Type.PREVIOUS:
				mat.emission = Color(0.6, 0.7, 0.8)
			Type.RACE:
				mat.emission = Color(0.8, 0.6, 0.1)
			Type.LAP:
				mat.emission = Color(0.1, 0.1, 0.8)
		mat.emission_enabled = true
		
		for child in get_children():
			(child as MeshInstance).material_override = mat


func update_transform() -> void:
	if frame < replay.size():
		var xform: Array = replay[frame]
		var basis_x := Vector3(xform[0], xform[1], xform[2])
		var basis_y := Vector3(xform[3], xform[4], xform[5])
		var basis_z := Vector3(xform[6], xform[7], xform[8])
		var origin := Vector3(xform[9], xform[10], xform[11])
		global_transform = Transform(basis_x, basis_y, basis_z, origin)


func read_replay():
	replay.clear()
	match type:
		Type.PREVIOUS:
			replay_path = replay_path.replace(".rpl", "_prev.rpl")
		Type.RACE:
			replay_path = replay_path.replace(".rpl", "_race.rpl")
		Type.LAP:
			replay_path = replay_path.replace(".rpl", "_lap.rpl")
	var file := File.new()
	var err := file.open(replay_path, File.READ)
	if err == OK:
		while not file.eof_reached():
			var line := file.get_line()
			if line == "":
				break
			var xform: Array = line.split(",")
			replay.append(xform)
		update_drone_model(replay[0][0])
		


func start_replay() -> void:
	visible = true
	state = State.PLAYING


func stop_replay() -> void:
	state = State.STANDBY
	visible = false


func reset_replay() -> void:
	frame = 0
