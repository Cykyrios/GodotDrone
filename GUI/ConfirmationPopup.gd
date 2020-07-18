extends Control


onready var title := $PanelContainer/VBoxContainer/Label
onready var button_yes := $PanelContainer/VBoxContainer/HBoxContainer/ButtonYes
onready var button_no := $PanelContainer/VBoxContainer/HBoxContainer/ButtonNo
onready var button_alt := $PanelContainer/VBoxContainer/HBoxContainer/ButtonAlt

signal validated


func _ready() -> void:
	var _discard = button_yes.connect("pressed", self, "_on_button_pressed", [0])
	_discard = button_no.connect("pressed", self, "_on_button_pressed", [1])
	_discard = button_alt.connect("pressed", self, "_on_button_pressed", [2])
	_discard = $PanelContainer.connect("resized", self, "_on_resized")


func _on_resized() -> void:
	rect_size = $PanelContainer.rect_size
	rect_position = (get_parent().rect_size - rect_size) / 2


func _on_button_pressed(choice: int) -> void:
	emit_signal("validated", choice)
	queue_free()


func set_text(text: String) -> void:
	title.text = text


func set_yes_button(text: String) -> void:
	button_yes.text = text


func set_no_button(text: String) -> void:
	button_no.text = text


func set_alt_button(text: String) -> void:
	button_alt.text = text


func set_buttons(yes: String = "OK", no: String = "", alt: String = "") -> void:
	button_yes.text = yes
	if button_no:
		button_no.text = no
	if button_alt:
		button_alt.text = alt
	if alt == "":
		remove_alt_button()
	if no == "":
		remove_no_button()


func remove_no_button() -> void:
	button_no.disconnect("pressed", self, "_on_button_pressed")
	button_no.queue_free()


func remove_alt_button() -> void:
	button_alt.disconnect("pressed", self, "_on_button_pressed")
	button_alt.queue_free()
