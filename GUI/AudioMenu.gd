extends Control


signal back


@onready var master_volume := $%MasterSlider as HSlider
@onready var master_volume_label := $%MasterValue as Label
@onready var button_back := $%ButtonBack as Button


func _ready() -> void:
	var _discard = master_volume.value_changed.connect(_on_master_volume_changed)
	master_volume.value = volume_to_slider(Audio.audio_settings["master_volume"])
	master_volume_label.text = update_slider_label(master_volume.value)

	_discard = button_back.pressed.connect(_on_back_pressed)


func _input(event):
	if event.is_action("ui_cancel") and event.is_pressed() and not event.is_echo():
		accept_event()
		back.emit()


func _on_master_volume_changed(value: float) -> void:
	master_volume_label.text = update_slider_label(master_volume.value)
	Audio.audio_settings["master_volume"] = slider_to_volume(value)
	Audio.update_master_volume()
	Audio.save_audio_settings()


func _on_back_pressed() -> void:
	back.emit()


func volume_to_slider(volume: float) -> float:
	return volume * 100.0


func slider_to_volume(value: float) -> float:
	return value / 100.0


func update_slider_label(value: float) -> String:
	var text := "%d%%" % [round(value)]
	return text
