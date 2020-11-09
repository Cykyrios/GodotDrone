extends MarginContainer


signal back


onready var label := $PanelContainer/VBoxContainer/RichTextLabel


func _ready() -> void:
	var _discard = label.connect("meta_clicked", self, "_on_url_clicked")
	_discard = $PanelContainer/VBoxContainer/ButtonBack.connect("pressed", self, "_on_back_pressed")
	
	label.bbcode_enabled = true
	
	label.append_bbcode("Please note this game is a Work In Progress! Feel free to report issues ")
	label.append_bbcode("[url=https://github.com/Cykyrios/GodotDrone]on GitHub[/url].")
	label.append_bbcode("\n\n")
	label.append_bbcode("You need a gamepad or radio transmitter to play, or really any device with 4 axes ")
	label.append_bbcode("that your computer recognizes.")
	label.append_bbcode("\n\n")
	label.append_bbcode("Keyboard controls are hard-coded at this time and are the following:")
	label.append_bbcode("\n\t- C changes the active camera")
	label.append_bbcode("\n\t- R toggles race mode, which spawns the drone on the closest launch pad")
	label.append_bbcode("\n\t- M cycles through flight modes")
	label.append_bbcode("\n\t- Backspace respawns the drone and resets the race")
	label.append_bbcode("\n\t- Escape brings up the pause menu")
	label.append_bbcode("\n\n")
	label.append_bbcode("The following flight modes are available, with the corresponding LED color:")
	label.append_bbcode("\n\t- red: acro")
	label.append_bbcode("\n\t- blue: horizon")
	label.append_bbcode("\n\t- yellow: speed")
	label.append_bbcode("\n\t- green: position")
	label.append_bbcode("\n\t- flashing red: recovery")
	label.append_bbcode("\n\n")
	label.append_bbcode("All stabilized modes hold altitude as well. Stabilized modes trigger recovery mode ")
	label.append_bbcode("when a bank angle of 45 degrees is exceeded.")
	label.append_bbcode("\n\n")
	label.append_bbcode("Starting the drone: In order to fly, the drone must first be armed. To that end, ")
	label.append_bbcode("throttle should be at or very close to zero, and the Arm switch/button ")
	label.append_bbcode("should be flicked/pressed. In the controls menu, \"Arm (hold)\" is supposed to be used ")
	label.append_bbcode("with a switch, and \"Arm (toggle)\" is supposed to be used with a button.")
	label.append_bbcode("\n\n")
	label.append_bbcode("Assigning the same axis to multiple actions is possible for potentiometers and 3-position ")
	label.append_bbcode("switches, as you can define the active range of every action controlled by an axis.")
	label.append_bbcode("\n\n")


func _input(event):
	if event.is_action("ui_cancel") and event.is_pressed() and not event.is_echo():
		accept_event()
		emit_signal("back")


func _on_url_clicked(meta) -> void:
	var _discard = OS.shell_open(meta)


func _on_back_pressed() -> void:
	emit_signal("back")
