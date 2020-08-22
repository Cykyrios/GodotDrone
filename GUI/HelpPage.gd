extends MarginContainer


signal back


onready var label := $PanelContainer/VBoxContainer/RichTextLabel


func _ready() -> void:
	var _discard = label.connect("meta_clicked", self, "_on_url_clicked")
	_discard = $PanelContainer/VBoxContainer/ButtonBack.connect("pressed", self, "_on_back_pressed")
	
	label.bbcode_enabled = true
	label.bbcode_text = """Please note this game is a Work In Progress! Feel free to report issues [url=https://github.com/Cykyrios/GodotDrone]on GitHub[/url].
	
	You need a gamepad or radio transmitter to play, or really any device with 4 axes that your computer recognizes.
	
	Keyboard controls are hard-coded at this time and are the following:
		- C changes the active camera
		- R toggles race mode, which spawns the drone on the closest launch pad
		- M cycles through flight modes
		- Backspace respawns the drone and resets the race
		- Escape brings up the pause menu
	
	The following flight modes are available, with the corresponding LED color:
		- red: acro
		- blue: horizon
		- yellow: speed
		- green: position
		- flashing red: recovery
	
	All stabilized modes hold altitude as well. Stabilized modes trigger recovery mode when a bank angle of 45 degrees is exceeded."""


func _input(event):
	if event is InputEventKey and event.is_pressed() and event.scancode == KEY_ESCAPE:
		accept_event()
		emit_signal("back")


func _on_url_clicked(meta) -> void:
	var _discard = OS.shell_open(meta)


func _on_back_pressed() -> void:
	emit_signal("back")
