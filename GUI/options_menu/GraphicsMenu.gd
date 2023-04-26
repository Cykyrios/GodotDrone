extends Control


signal back


@onready var window_mode := %WindowOptions as OptionButton
@onready var resolution := %ResolutionOptions as OptionButton
@onready var game_msaa := %GameMSAAOptions as OptionButton
@onready var game_af := %GameAFOptions as OptionButton
@onready var shadows := %ShadowsOptions as OptionButton
@onready var fisheye_mode := %FPVFisheyeOptions as OptionButton
@onready var fisheye_resolution := %FisheyeResolutionOptions as OptionButton
@onready var fisheye_msaa := %FisheyeMSAAOptions as OptionButton

@onready var button_back := %ButtonBack as Button


func _ready() -> void:
	window_mode.get_popup().add_item("Full Screen")
	window_mode.get_popup().add_item("Window")
	window_mode.get_popup().add_item("Borderless Window")
	var _discard = window_mode.item_selected.connect(_on_window_mode_changed)
	window_mode.select(Graphics.graphics_settings["window_mode"])

	resolution.get_popup().add_item("100%")
	resolution.get_popup().add_item("75%")
	resolution.get_popup().add_item("50%")
	_discard = resolution.item_selected.connect(_on_resolution_changed)
	var res := Graphics.graphics_settings["resolution"] as int
	var option := 0
	match res:
		100:
			option = 0
		75:
			option = 1
		50:
			option = 2
	resolution.select(option)

	game_msaa.get_popup().add_item("Off")
	game_msaa.get_popup().add_item("2x")
	game_msaa.get_popup().add_item("4x")
	game_msaa.get_popup().add_item("8x")
	game_msaa.get_popup().add_item("16x")
	_discard = game_msaa.item_selected.connect(_on_msaa_changed)
	game_msaa.select(Graphics.graphics_settings["msaa"])

	game_af.get_popup().add_item("Off")
	game_af.get_popup().add_item("2x")
	game_af.get_popup().add_item("4x")
	game_af.get_popup().add_item("8x")
	game_af.get_popup().add_item("16x")
	_discard = game_af.item_selected.connect(_on_af_changed)
	game_af.select(Graphics.graphics_settings["af"])

	shadows.get_popup().add_item("Very Low")
	shadows.get_popup().add_item("Low")
	shadows.get_popup().add_item("Medium")
	shadows.get_popup().add_item("High")
	shadows.get_popup().add_item("Ultra")
	_discard = shadows.item_selected.connect(_on_shadows_changed)
	shadows.select(Graphics.graphics_settings["shadows"])

	fisheye_mode.get_popup().add_item("Off")
	fisheye_mode.get_popup().add_item("Full")
	fisheye_mode.get_popup().add_item("Fast")
	_discard = fisheye_mode.item_selected.connect(_on_fisheye_mode_changed)
	fisheye_mode.select(Graphics.graphics_settings["fisheye_mode"])

	fisheye_resolution.get_popup().add_item("2160p")
	fisheye_resolution.get_popup().add_item("1440p")
	fisheye_resolution.get_popup().add_item("1080p")
	fisheye_resolution.get_popup().add_item("720p")
	fisheye_resolution.get_popup().add_item("480p")
	fisheye_resolution.get_popup().add_item("240p")
	_discard = fisheye_resolution.item_selected.connect(_on_fisheye_resolution_changed)
	fisheye_resolution.select(Graphics.graphics_settings["fisheye_resolution"])

	fisheye_msaa.get_popup().add_item("Off")
	fisheye_msaa.get_popup().add_item("2x")
	fisheye_msaa.get_popup().add_item("4x")
	fisheye_msaa.get_popup().add_item("8x")
	fisheye_msaa.get_popup().add_item("16x")
	fisheye_msaa.get_popup().add_item("Same as Game MSAA")
	_discard = fisheye_msaa.item_selected.connect(_on_fisheye_msaa_changed)
	fisheye_msaa.select(Graphics.graphics_settings["fisheye_msaa"])

	_discard = button_back.pressed.connect(_on_back_pressed)


func _input(event):
	if event.is_action("ui_cancel") and event.is_pressed() and not event.is_echo():
		accept_event()
		back.emit()


func _on_window_mode_changed(idx: int) -> void:
	Graphics.graphics_settings["window_mode"] = idx
	Graphics.update_window_mode()
	Graphics.save_graphics_settings()


func _on_resolution_changed(_idx: int) -> void:
	Graphics.graphics_settings["resolution"] = ((resolution.text as String).rstrip("%")) as int
	Graphics.update_resolution()
	Graphics.save_graphics_settings()


func _on_msaa_changed(idx: int) -> void:
	Graphics.graphics_settings["msaa"] = idx
	Graphics.update_msaa()
	Graphics.save_graphics_settings()


func _on_af_changed(idx: int) -> void:
	Graphics.graphics_settings["af"] = idx
	Graphics.update_af()
	Graphics.save_graphics_settings()


func _on_shadows_changed(idx: int) -> void:
	Graphics.graphics_settings["shadows"] = idx
	Graphics.update_shadows()
	Graphics.save_graphics_settings()


func _on_fisheye_mode_changed(idx: int) -> void:
	Graphics.graphics_settings["fisheye_mode"] = idx
	Graphics.update_fisheye_mode()
	Graphics.save_graphics_settings()

	var fisheye_disabled := false
	if idx == Graphics.FisheyeMode.OFF:
		fisheye_disabled = true
	fisheye_resolution.disabled = fisheye_disabled
	fisheye_msaa.disabled = fisheye_disabled


func _on_fisheye_resolution_changed(_idx: int) -> void:
	Graphics.update_fisheye_resolution(fisheye_resolution.text)
	Graphics.save_graphics_settings()


func _on_fisheye_msaa_changed(idx: int) -> void:
	Graphics.graphics_settings["fisheye_msaa"] = idx
	Graphics.save_graphics_settings()


func _on_back_pressed() -> void:
	back.emit()
