extends Camera
class_name FPVCamera


export (float, 90, 180) var fov_h := 150.0 setget set_fov
export (float, 0.001, 1) var clip_near := 0.005
export (float, 10, 10000) var clip_far := 1000.0

var viewports := []
var cameras := []
var camera_layer := 11
var num_cameras := 5
var fpv_environment: Environment = load("res://drone/FPVCamera/FPVCameraEnvironment.tres")

onready var render_quad: MeshInstance = null
var mat: ShaderMaterial = load("res://drone/FPVCamera/FPVCamera.tres")


func _ready() -> void:
	var _discard = Graphics.connect("fisheye_resolution_changed", self, "_on_fisheye_resolution_changed")
	_discard = Graphics.connect("fisheye_msaa_changed", self, "_on_fisheye_msaa_changed")
	
	var fisheye_mode: int = Graphics.graphics_settings["fisheye_mode"]
	if fisheye_mode == Graphics.FisheyeMode.OFF:
		near = clip_near
		far = clip_far
		return
	elif fisheye_mode == Graphics.FisheyeMode.FAST:
		num_cameras = 2
		mat.shader = load("res://drone/FPVCamera/FPVCamera_fast.shader")
	environment = fpv_environment
	cull_mask = int(pow(2, camera_layer - 1))
	render_quad = MeshInstance.new()
	add_child(render_quad)
	render_quad.translate_object_local(Vector3.FORWARD * (near + 0.1 * (far - near)))
	render_quad.rotate_object_local(Vector3.RIGHT, PI / 2)
	render_quad.mesh = QuadMesh.new()
	render_quad.mesh.size = Vector2(2, 2)
	render_quad.layers = int(pow(2, camera_layer - 1))
	render_quad.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF
	render_quad.mesh.surface_set_material(0, mat)
	render_quad.visible = false
	
	mat.set_shader_param("hfov", fov_h)
	
	var root_viewport: Viewport = get_tree().root
	for i in range(num_cameras):
		var viewport := Viewport.new()
		add_child(viewport)
		viewport.size = Graphics.fisheye_resolution * Vector2.ONE
		viewport.shadow_atlas_size = root_viewport.shadow_atlas_size
		if Graphics.graphics_settings["fisheye_msaa"] == Graphics.FisheyeMSAA.SAME_AS_GAME:
			viewport.msaa = root_viewport.msaa
		else:
			viewport.msaa = Graphics.graphics_settings["fisheye_msaa"]
		viewport.hdr = true
		viewport.keep_3d_linear = true
		viewports.append(viewport)
		mat.set_shader_param("Texture%d" % [i], viewports[i].get_texture())
		
		var camera := Camera.new()
		viewport.add_child(camera)
		camera.fov = 90
		if fisheye_mode == Graphics.FisheyeMode.FAST and i == 1:
			camera.fov = 160
		camera.near = clip_near
		camera.far = clip_far
		camera.cull_mask -= int(pow(2, camera_layer - 1))
		camera.environment = fpv_environment
		cameras.append(camera)


func _process(_delta: float) -> void:
	var fisheye_mode: int = Graphics.graphics_settings["fisheye_mode"]
	if fisheye_mode != Graphics.FisheyeMode.OFF:
		for camera in cameras:
			camera.global_transform = global_transform
		if fisheye_mode == Graphics.FisheyeMode.FULL:
			cameras[1].rotate_object_local(Vector3.UP, PI/2)
			cameras[2].rotate_object_local(Vector3.UP, -PI/2)
			cameras[3].rotate_object_local(Vector3.RIGHT, -PI/2)
			cameras[4].rotate_object_local(Vector3.RIGHT, PI/2)


func set_fov(angle: float) -> void:
	fov_h = angle
	mat.set_shader_param("hfov", fov_h)


func show_fisheye(show: bool) -> void:
	render_quad.visible = show


func _on_fisheye_resolution_changed() -> void:
	for viewport in viewports:
		viewport.size = Graphics.fisheye_resolution * Vector2.ONE


func _on_fisheye_msaa_changed() -> void:
	for viewport in viewports:
		if Graphics.graphics_settings["fisheye_msaa"] == Graphics.FisheyeMSAA.SAME_AS_GAME:
			viewport.msaa = Graphics.graphics_settings["msaa"]
		else:
			viewport.msaa = Graphics.graphics_settings["fisheye_msaa"]
