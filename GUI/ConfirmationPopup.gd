extends Control


onready var title = $PanelContainer/VBoxContainer/Label
onready var button_yes = $PanelContainer/VBoxContainer/HBoxContainer/ButtonYes
onready var button_no = $PanelContainer/VBoxContainer/HBoxContainer/ButtonNo
onready var button_alt = $PanelContainer/VBoxContainer/HBoxContainer/ButtonAlt

signal validated


func _ready():
	button_yes.connect("pressed", self, "_on_button_pressed", [0])
	button_no.connect("pressed", self, "_on_button_pressed", [1])
	button_alt.connect("pressed", self, "_on_button_pressed", [2])


func _on_button_pressed(choice : int):
	emit_signal("validated", choice)
	queue_free()


func set_text(text : String):
	title.text = text


func set_yes_button(text : String):
	button_yes.text = text


func set_no_button(text : String):
	button_no.text = text


func set_alt_button(text : String):
	button_alt.text = text


func set_buttons(yes : String = "OK", no : String = "", alt : String = ""):
	button_yes.text = yes
	if button_no:
		button_no.text = no
	if button_alt:
		button_alt.text = alt
	if alt == "":
		remove_alt_button()
	if no == "":
		remove_no_button()


func remove_no_button():
	button_no.disconnect("pressed", self, "_on_button_pressed")
	button_no.queue_free()


func remove_alt_button():
	button_alt.disconnect("pressed", self, "_on_button_pressed")
	button_alt.queue_free()
