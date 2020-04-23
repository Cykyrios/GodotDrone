extends Control


onready var title = $PanelContainer/VBoxContainer/Label
onready var button_yes = $PanelContainer/VBoxContainer/HBoxContainer/ButtonYes
onready var button_no = $PanelContainer/VBoxContainer/HBoxContainer/ButtonNo
onready var button_alt = $PanelContainer/VBoxContainer/HBoxContainer/ButtonAlt

var add_alt = true

signal validated


func _ready():
	if !add_alt:
		button_alt.queue_free()
	button_yes.connect("pressed", self, "_on_button_pressed", [0])
	button_no.connect("pressed", self, "_on_button_pressed", [1])
	button_alt.connect("pressed", self, "_on_button_pressed", [2])


func _on_button_pressed(choice : int):
	emit_signal("validated", choice)


func set_text(text : String):
	title.text = text


func set_yes_button(text : String):
	button_yes.text = text


func set_no_button(text : String):
	button_no.text = text


func set_alt_button(text : String):
	button_alt.text = text


func remove_alt_button():
	button_alt.disconnect("pressed", self, "_on_button_pressed")
	button_alt.queue_free()
