class_name FPVCamera
extends Camera3D


@export_range (90, 180) var fov_h := 150.0 :
	set(angle):
		fov_h = angle
		mat.set_shader_parameter("hfov", fov_h)
@export_range (0.001, 1) var clip_near := 0.005
@export_range (10, 10000) var clip_far := 1000.0

var viewports: Array[SubViewport] = []
var cameras: Array[Camera3D] = []
var camera_layer := 11
var num_cameras := 5

@onready var render_quad: MeshInstance3D = null
var mat: ShaderMaterial = load("res://drone/fpv_camera/fpv_camera.tres")


func _ready() -> void:
	var _discard := Graphics.fisheye_resolution_changed.connect(_on_fisheye_resolution_changed)
	_discard = Graphics.fisheye_msaa_changed.connect(_on_fisheye_msaa_changed)

	var fisheye_mode: int = Graphics.graphics_settings["fisheye_mode"]
	if fisheye_mode == Graphics.FisheyeMode.OFF:
		near = clip_near
		far = clip_far
		return
	elif fisheye_mode == Graphics.FisheyeMode.FAST:
		num_cameras = 2
		mat.shader = load("res://drone/fpv_camera/fpv_camera_fast.gdshader")
	cull_mask = int(pow(2, camera_layer - 1))
	render_quad = MeshInstance3D.new()
	add_child(render_quad)
	render_quad.translate_object_local(Vector3.FORWARD * (near + 0.1))
	render_quad.mesh = QuadMesh.new()
	render_quad.mesh.size = Vector2(2, 2)
	render_quad.layers = int(pow(2, camera_layer - 1))
	render_quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	render_quad.mesh.material = mat
	render_quad.visible = false

	mat.set_shader_parameter("hfov", fov_h)

	var root_viewport := get_tree().root as Viewport
	for i in num_cameras:
		var viewport := SubViewport.new()
		add_child(viewport)
		viewport.size = Graphics.fisheye_resolution * Vector2.ONE
		viewport.positional_shadow_atlas_size = root_viewport.positional_shadow_atlas_size
		if Graphics.graphics_settings["fisheye_msaa"] == Graphics.FisheyeMSAA.SAME_AS_GAME:
			viewport.msaa_3d = root_viewport.msaa_3d
		else:
			viewport.msaa_3d = Graphics.graphics_settings["fisheye_msaa"]
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		viewports.append(viewport)

		var camera := Camera3D.new()
		viewport.add_child(camera)
		camera.fov = 100
		if fisheye_mode == Graphics.FisheyeMode.FAST and i == 1:
			camera.fov = 160
		camera.near = clip_near
		camera.far = clip_far
		camera.cull_mask -= int(pow(2, camera_layer - 1))
		cameras.append(camera)

		var camera_attributes := CameraAttributesPractical.new()
		camera.attributes = camera_attributes

	update_viewport_textures.call_deferred()


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


func show_fisheye(fisheye: bool) -> void:
	render_quad.visible = fisheye


func _on_fisheye_resolution_changed() -> void:
	for viewport in viewports:
		viewport.size = Graphics.fisheye_resolution * Vector2.ONE


func _on_fisheye_msaa_changed() -> void:
	for viewport in viewports:
		if Graphics.graphics_settings["fisheye_msaa"] == Graphics.FisheyeMSAA.SAME_AS_GAME:
			viewport.msaa_3d = Graphics.graphics_settings["msaa"]
		else:
			viewport.msaa_3d = Graphics.graphics_settings["fisheye_msaa"]


func update_viewport_textures() -> void:
	await RenderingServer.frame_post_draw
	for i in num_cameras:
		var viewport := viewports[i] as SubViewport
		var viewport_texture := viewport.get_texture()
		mat.set_shader_parameter("Texture%d" % [i], viewport_texture)
