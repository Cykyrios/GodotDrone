extends MarginContainer


signal back


@onready var label := %HelpLabel as RichTextLabel
@onready var button_back := %ButtonBack as Button


func _ready() -> void:
	var _discard = label.meta_clicked.connect(_on_url_clicked)
	_discard = button_back.pressed.connect(_on_back_pressed)

	label.bbcode_enabled = true

	label.append_text("Please note this game is a Work In Progress! Feel free to report issues ")
	label.append_text("[url=https://github.com/Cykyrios/GodotDrone]on GitHub[/url].")
	label.append_text("\n\n")
	label.append_text("You need a gamepad or radio transmitter to play, or really any device with 4 ")
	label.append_text("axes that your computer recognizes.")
	label.append_text("\n\n")
	label.append_text("Keyboard controls are hard-coded at this time and are the following:")
	label.append_text("\n\t- C changes the active camera")
	label.append_text("\n\t- R toggles race mode, which spawns the drone on the closest launch pad")
	label.append_text("\n\t- M cycles through flight modes")
	label.append_text("\n\t- Backspace respawns the drone and resets the race")
	label.append_text("\n\t- Escape brings up the pause menu")
	label.append_text("\n\n")
	label.append_text("The following flight modes are available, with the corresponding LED color:")
	label.append_text("\n\t- red: acro")
	label.append_text("\n\t- blue: horizon")
	label.append_text("\n\t- yellow: speed")
	label.append_text("\n\t- green: position")
	label.append_text("\n\t- flashing red: recovery")
	label.append_text("\n\n")
	label.append_text("All stabilized modes hold altitude as well. Stabilized modes trigger recovery ")
	label.append_text("mode when a bank angle of 45 degrees is exceeded.")
	label.append_text("\n\n")
	label.append_text("Starting the drone: In order to fly, the drone must first be armed. To that end, ")
	label.append_text("throttle should be at or very close to zero, and the Arm switch/button ")
	label.append_text("should be flicked/pressed. In the controls menu, \"Arm (hold)\" is supposed to ")
	label.append_text("be used with a switch, and \"Arm (toggle)\" is supposed to be used with a button.")
	label.append_text("\n\n")
	label.append_text("Assigning the same axis to multiple actions is possible for potentiometers ")
	label.append_text("and 3-position switches, as you can define the active range of every action ")
	label.append_text("controlled by an axis.")
	label.append_text("\n\n")


func _input(event: InputEvent) -> void:
	if event.is_action("ui_cancel") and event.is_pressed() and not event.is_echo():
		accept_event()
		back.emit()


func _on_url_clicked(meta: Variant) -> void:
	var _discard = OS.shell_open(meta)


func _on_back_pressed() -> void:
	back.emit()
