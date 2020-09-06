extends Control


signal back


var packed_popup := preload("res://GUI/ConfirmationPopup.tscn")

onready var window_mode := $PanelContainer/VBoxContainer/ScrollContainer/WindowGrid/WindowOptions
onready var resolution := $PanelContainer/VBoxContainer/ScrollContainer/WindowGrid/ResolutionOptions
onready var game_msaa := $PanelContainer/VBoxContainer/ScrollContainer/WindowGrid/GameMSAAOptions
onready var game_af := $PanelContainer/VBoxContainer/ScrollContainer/WindowGrid/GameAFOptions
onready var shadows := $PanelContainer/VBoxContainer/ScrollContainer/WindowGrid/ShadowsOptions
onready var fisheye_mode := $PanelContainer/VBoxContainer/ScrollContainer/WindowGrid/FPVFisheyeOptions
onready var fisheye_resolution := $PanelContainer/VBoxContainer/ScrollContainer/WindowGrid/FisheyeResolutionOptions
onready var fisheye_msaa := $PanelContainer/VBoxContainer/ScrollContainer/WindowGrid/FisheyeMSAAOptions


func _ready() -> void:
	window_mode.get_popup().add_item("Full Screen")
	window_mode.get_popup().add_item("Full Screen Window")
	window_mode.get_popup().add_item("Window")
	window_mode.get_popup().add_item("Borderless Window")
	var _discard = window_mode.connect("item_selected", self, "_on_window_mode_changed")
	window_mode.select(Graphics.graphics_settings["window_mode"])
	
	resolution.get_popup().add_item("100%")
	resolution.get_popup().add_item("75%")
	resolution.get_popup().add_item("50%")
	_discard = resolution.connect("item_selected", self, "_on_resolution_changed")
	var res: int = Graphics.graphics_settings["resolution"]
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
	_discard = game_msaa.connect("item_selected", self, "_on_msaa_changed")
	game_msaa.select(Graphics.graphics_settings["msaa"])
	
	game_af.get_popup().add_item("Off")
	game_af.get_popup().add_item("2x")
	game_af.get_popup().add_item("4x")
	game_af.get_popup().add_item("8x")
	game_af.get_popup().add_item("16x")
	_discard = game_af.connect("item_selected", self, "_on_af_changed")
	game_af.select(Graphics.graphics_settings["af"])
	
	shadows.get_popup().add_item("Off")
	shadows.get_popup().add_item("Low")
	shadows.get_popup().add_item("Medium")
	shadows.get_popup().add_item("High")
	shadows.get_popup().add_item("Ultra")
	_discard = shadows.connect("item_selected", self, "_on_shadows_changed")
	shadows.select(Graphics.graphics_settings["shadows"])
	shadows.disabled = true
	
	fisheye_mode.get_popup().add_item("Off")
	fisheye_mode.get_popup().add_item("Full")
	fisheye_mode.get_popup().add_item("Fast")
	_discard = fisheye_mode.connect("item_selected", self, "_on_fisheye_mode_changed")
	fisheye_mode.select(Graphics.graphics_settings["fisheye_mode"])
	
	fisheye_resolution.get_popup().add_item("2160p")
	fisheye_resolution.get_popup().add_item("1440p")
	fisheye_resolution.get_popup().add_item("1080p")
	fisheye_resolution.get_popup().add_item("720p")
	fisheye_resolution.get_popup().add_item("480p")
	fisheye_resolution.get_popup().add_item("240p")
	_discard = fisheye_resolution.connect("item_selected", self, "_on_fisheye_resolution_changed")
	fisheye_resolution.select(Graphics.graphics_settings["fisheye_resolution"])
	
	fisheye_msaa.get_popup().add_item("Off")
	fisheye_msaa.get_popup().add_item("2x")
	fisheye_msaa.get_popup().add_item("4x")
	fisheye_msaa.get_popup().add_item("8x")
	fisheye_msaa.get_popup().add_item("16x")
	fisheye_msaa.get_popup().add_item("Same as Game MSAA")
	_discard = fisheye_msaa.connect("item_selected", self, "_on_fisheye_msaa_changed")
	fisheye_msaa.select(Graphics.graphics_settings["fisheye_msaa"])
	
	_discard = $PanelContainer/VBoxContainer/HBoxContainer/ButtonBack.connect("pressed", self, "_on_back_pressed")


func _input(event):
	if event is InputEventKey and event.is_pressed() and event.scancode == KEY_ESCAPE:
		accept_event()
		emit_signal("back")


func _on_window_mode_changed(idx: int) -> void:
	Graphics.graphics_settings["window_mode"] = idx
	Graphics.update_window_mode()
	Graphics.save_graphics_settings()


func _on_resolution_changed(_idx: int) -> void:
	Graphics.graphics_settings["resolution"] = int((resolution.text as String).rstrip("%"))
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
	emit_signal("back")
