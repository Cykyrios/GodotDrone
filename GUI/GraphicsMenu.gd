extends Control


signal back


var packed_popup = preload("res://GUI/ConfirmationPopup.tscn")

onready var window_mode = $PanelContainer/VBoxContainer/ScrollContainer/WindowGrid/WindowOptions
onready var resolution = $PanelContainer/VBoxContainer/ScrollContainer/WindowGrid/ResolutionOptions
onready var game_msaa = $PanelContainer/VBoxContainer/ScrollContainer/WindowGrid/GameMSAAOptions
onready var game_af = $PanelContainer/VBoxContainer/ScrollContainer/WindowGrid/GameAFOptions
onready var shadows = $PanelContainer/VBoxContainer/ScrollContainer/WindowGrid/ShadowsOptions
onready var fisheye_mode = $PanelContainer/VBoxContainer/ScrollContainer/WindowGrid/FPVFisheyeOptions
onready var fisheye_resolution = $PanelContainer/VBoxContainer/ScrollContainer/WindowGrid/FisheyeResolutionOptions
onready var fisheye_msaa = $PanelContainer/VBoxContainer/ScrollContainer/WindowGrid/FisheyeMSAAOptions


func _ready():
	window_mode.get_popup().add_item("Full Screen")
	window_mode.get_popup().add_item("Full Screen Window")
	window_mode.get_popup().add_item("Window")
	window_mode.get_popup().add_item("Borderless Window")
	window_mode.connect("item_selected", self, "_on_window_mode_changed")
	window_mode.select(Graphics.graphics_settings["window_mode"])
	
	resolution.get_popup().add_item("Monitor Resolution")
	resolution.get_popup().add_item("1920x1080")
	resolution.get_popup().add_item("1280x720")
	resolution.connect("item_selected", self, "_on_resolution_changed")
#	resolution.select(Graphics.graphics_settings["resolution"])
	
	game_msaa.get_popup().add_item("Off")
	game_msaa.get_popup().add_item("2x")
	game_msaa.get_popup().add_item("4x")
	game_msaa.get_popup().add_item("8x")
	game_msaa.get_popup().add_item("16x")
	game_msaa.connect("item_selected", self, "_on_msaa_changed")
	game_msaa.select(Graphics.graphics_settings["msaa"])
	
	game_af.get_popup().add_item("Off")
	game_af.get_popup().add_item("2x")
	game_af.get_popup().add_item("4x")
	game_af.get_popup().add_item("8x")
	game_af.get_popup().add_item("16x")
	game_af.connect("item_selected", self, "_on_af_changed")
	game_af.select(Graphics.graphics_settings["af"])
	
	shadows.get_popup().add_item("Off")
	shadows.get_popup().add_item("Low")
	shadows.get_popup().add_item("Medium")
	shadows.get_popup().add_item("High")
	shadows.get_popup().add_item("Ultra")
	shadows.connect("item_selected", self, "_on_shadows_changed")
	shadows.select(Graphics.graphics_settings["shadows"])
	
	fisheye_mode.get_popup().add_item("Off")
	fisheye_mode.get_popup().add_item("Full")
	fisheye_mode.get_popup().add_item("Fast")
	fisheye_mode.connect("item_selected", self, "_on_fisheye_mode_changed")
	fisheye_mode.select(Graphics.graphics_settings["fisheye_mode"])
	
	fisheye_resolution.get_popup().add_item("2160p")
	fisheye_resolution.get_popup().add_item("1440p")
	fisheye_resolution.get_popup().add_item("1080p")
	fisheye_resolution.get_popup().add_item("720p")
	fisheye_resolution.get_popup().add_item("480p")
	fisheye_resolution.get_popup().add_item("240p")
	fisheye_resolution.connect("item_selected", self, "_on_fisheye_resolution_changed")
	fisheye_resolution.select(Graphics.graphics_settings["fisheye_resolution"])
	
	fisheye_msaa.get_popup().add_item("Off")
	fisheye_msaa.get_popup().add_item("2x")
	fisheye_msaa.get_popup().add_item("4x")
	fisheye_msaa.get_popup().add_item("8x")
	fisheye_msaa.get_popup().add_item("16x")
	fisheye_msaa.get_popup().add_item("Same as Game MSAA")
	fisheye_msaa.connect("item_selected", self, "_on_fisheye_msaa_changed")
	fisheye_msaa.select(Graphics.graphics_settings["fisheye_msaa"])
	
	$PanelContainer/VBoxContainer/HBoxContainer/ButtonBack.connect("pressed", self, "_on_back_pressed")


func _on_window_mode_changed(idx: int):
	Graphics.graphics_settings["window_mode"] = idx
	Graphics.update_window_mode()
	Graphics.save_graphics_settings()


func _on_resolution_changed(idx: int):
	Graphics.graphics_settings["resolution"] = resolution.text
	Graphics.update_resolution()
	Graphics.save_graphics_settings()


func _on_msaa_changed(idx: int):
	Graphics.graphics_settings["msaa"] = idx
	Graphics.update_msaa()
	Graphics.save_graphics_settings()


func _on_af_changed(idx: int):
	Graphics.graphics_settings["af"] = idx
	Graphics.update_af()
	Graphics.save_graphics_settings()


func _on_shadows_changed(idx: int):
	Graphics.graphics_settings["shadows"] = idx
	Graphics.update_shadows()
	Graphics.save_graphics_settings()


func _on_fisheye_mode_changed(idx: int):
	Graphics.graphics_settings["fisheye_mode"] = idx
	Graphics.update_fisheye_mode()
	Graphics.save_graphics_settings()


func _on_fisheye_resolution_changed(idx: int):
	Graphics.update_fisheye_resolution(fisheye_resolution.text)
	Graphics.save_graphics_settings()


func _on_fisheye_msaa_changed(idx: int):
	Graphics.graphics_settings["fisheye_msaa"] = idx
	Graphics.save_graphics_settings()


func _on_apply_pressed():
	pass


func _on_back_pressed():
#	var confirm_dialog = packed_popup.instance()
#	add_child(confirm_dialog)
#	confirm_dialog.set_text("Do you really want to quit?")
#	confirm_dialog.set_buttons("Quit", "Cancel")
#	confirm_dialog.show_modal(true)
#	var dialog = yield(confirm_dialog, "validated")
#	if dialog == 0:
	emit_signal("back")
