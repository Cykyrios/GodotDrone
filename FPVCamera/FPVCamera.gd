extends Camera
class_name FPVCamera


export (float, 90, 180) var fov_h = 150 setget set_fov
export (int, 240, 2160) var camera_resolution = 720
export (float, 0.001, 1) var clip_near = 0.005
export (float, 10, 10000) var clip_far = 1000

var viewports = []
var cameras = []
var num_cameras = 5
var fpv_environment: Environment = load("res://FPVCamera/FPVCameraEnvironment.tres")

onready var render_quad: MeshInstance = null
var mat = load("res://FPVCamera/FPVCamera.tres")


func _ready():
	render_quad = MeshInstance.new()
	add_child(render_quad)
	render_quad.translate_object_local(Vector3.FORWARD * (near + 0.1 * (far - near)))
	render_quad.rotate_object_local(Vector3.RIGHT, PI / 2)
	render_quad.mesh = QuadMesh.new()
	render_quad.mesh.size = Vector2(2, 2)
	render_quad.layers = 1024
	render_quad.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF
	render_quad.mesh.surface_set_material(0, mat)
	render_quad.visible = false
	
	mat.set_shader_param("hfov", fov_h)
	
	var root_viewport: Viewport = get_tree().root
	for i in range(num_cameras):
		var viewport = Viewport.new()
		add_child(viewport)
		viewport.size = camera_resolution * Vector2.ONE
		viewport.shadow_atlas_size = root_viewport.shadow_atlas_size
		viewport.msaa = root_viewport.msaa
		viewport.hdr = true
		viewport.keep_3d_linear = true
		viewports.append(viewport)
		mat.set_shader_param("Texture%d" % [i], viewports[i].get_texture())
		
		var camera = Camera.new()
		viewport.add_child(camera)
		camera.fov = 90
		camera.near = clip_near
		camera.far = clip_far
		camera.cull_mask -= 1024
		camera.environment = fpv_environment
		cameras.append(camera)


func _process(delta):
	for camera in cameras:
		camera.global_transform = global_transform
	cameras[1].rotate_object_local(Vector3.UP, PI/2)
	cameras[2].rotate_object_local(Vector3.UP, -PI/2)
	cameras[3].rotate_object_local(Vector3.RIGHT, -PI/2)
	cameras[4].rotate_object_local(Vector3.RIGHT, PI/2)


func set_fov(angle: float):
	fov_h = angle
	mat.set_shader_param("hfov", fov_h)


func show_fisheye(show: bool):
	render_quad.visible = show
