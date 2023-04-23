class_name BindingPopup
extends PanelContainer

signal confirm_pressed
signal cancel_pressed
signal clear_pressed

var vbox := VBoxContainer.new()
var label := Label.new()
var hbox := HBoxContainer.new()
var button_confirm := Button.new()
var button_cancel := Button.new()
var button_clear := Button.new()


func _ready() -> void:
	add_child(vbox)
	vbox.add_child(label)
	vbox.add_child(hbox)
	hbox.add_child(button_confirm)
	hbox.add_child(button_cancel)
	hbox.add_child(button_clear)

	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER

	button_confirm.text = "Confirm"
	button_cancel.text = "Cancel"
	button_clear.text = "Clear"
	var _discard = button_confirm.pressed.connect(func(): confirm_pressed.emit())
	_discard = button_cancel.pressed.connect(func(): cancel_pressed.emit())
	_discard = button_clear.pressed.connect(func(): clear_pressed.emit())


func set_text(text: String) -> void:
	label.text = text
