class_name Ghost
extends Node3D


enum State {STANDBY, PLAYING}
enum Type {GOLD, SILVER, BRONZE, PREVIOUS, ABORTED}


var replay_path := ""
var replay := []
var type := Type.PREVIOUS
var state := State.STANDBY
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
		if child is MeshInstance3D:
			if child.name != "CW" and child.name != "CCW":
				var xform := get_mesh_transform(child)
				add_child(child.duplicate(0))
				get_child(get_child_count() - 1).transform = xform


func get_mesh_transform(node: Node) -> Transform3D:
	var xform: Transform3D = node.transform
	if not node.get_parent() is Drone:
		xform *= get_mesh_transform(node.get_parent())
	return xform


func update_drone_model(path: String) -> void:
	var drone_packed: PackedScene = load(path)
	if drone_packed.can_instantiate():
		var drone: Drone = drone_packed.instantiate()
		add_meshes(drone)
		drone.queue_free()

		var mat := StandardMaterial3D.new()
		mat.params_cull_mode = StandardMaterial3D.CULL_DISABLED
		mat.albedo_color = Color(0.7, 0.7, 0.7, 0.3)
		mat.distance_fade_mode = StandardMaterial3D.DISTANCE_FADE_PIXEL_DITHER
		mat.distance_fade_max_distance = 1.0
		mat.distance_fade_min_distance = 0.2
		match type:
			Type.GOLD:
				mat.emission = Color(0.8, 0.6, 0.1)
			Type.SILVER:
				mat.emission = Color(0.65, 0.7, 0.8)
			Type.BRONZE:
				mat.emission = Color(0.4, 0.2, 0.05)
			Type.PREVIOUS:
				mat.emission = Color(0.1, 0.1, 0.8)
			Type.ABORTED:
				mat.emission = Color(0.8, 0.1, 0.1)
		mat.emission_enabled = true

		for child in get_children():
			(child as MeshInstance3D).material_override = mat


func update_transform() -> void:
	if frame < replay.size():
		var xform: Array = replay[frame]
		var basis_x := Vector3(xform[0].to_float(), xform[1].to_float(), xform[2].to_float())
		var basis_y := Vector3(xform[3].to_float(), xform[4].to_float(), xform[5].to_float())
		var basis_z := Vector3(xform[6].to_float(), xform[7].to_float(), xform[8].to_float())
		var origin := Vector3(xform[9].to_float(), xform[10].to_float(), xform[11].to_float())
		global_transform = Transform3D(basis_x, basis_y, basis_z, origin)


func read_replay() -> void:
	replay.clear()
	match type:
		Type.PREVIOUS:
			replay_path = replay_path.replace(".rpl", "_prev.rpl")
		Type.GOLD:
			replay_path = replay_path.replace(".rpl", "_gold.rpl")
		Type.SILVER:
			replay_path = replay_path.replace(".rpl", "_silver.rpl")
		Type.BRONZE:
			replay_path = replay_path.replace(".rpl", "_bronze.rpl")
		Type.ABORTED:
			replay_path = replay_path.replace(".rpl", "_aborted.rpl")
	var file := FileAccess.open(replay_path, FileAccess.READ)
	if file:
		while not file.eof_reached():
			var line := file.get_line()
			if line == "":
				break
			var xform: Array = line.split(",")
			replay.append(xform)
		update_drone_model(replay[0][0])
		file = null



func start_replay() -> void:
	visible = true
	state = State.PLAYING


func stop_replay() -> void:
	state = State.STANDBY
	visible = false


func reset_replay() -> void:
	frame = 0
