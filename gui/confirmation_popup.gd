extends Popup


signal validated

@onready var popup_title := %Label as Label
@onready var button_yes := %ButtonYes as Button
@onready var button_no := %ButtonNo as Button
@onready var button_alt := %ButtonAlt as Button


func _ready() -> void:
	var _discard := button_yes.pressed.connect(_on_button_pressed.bind(0))
	_discard = button_no.pressed.connect(_on_button_pressed.bind(1))
	_discard = button_alt.pressed.connect(_on_button_pressed.bind(2))
	_discard = %PanelContainer.resized.connect(_on_resized)


func _on_resized() -> void:
	size = %PanelContainer.size
	position = (get_parent().size - (size as Vector2)) / 2


func _on_button_pressed(choice: int) -> void:
	validated.emit(choice)
	queue_free()


func set_text(text: String) -> void:
	popup_title.text = text


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
	button_no.pressed.disconnect(_on_button_pressed)
	button_no.queue_free()


func remove_alt_button() -> void:
	button_alt.pressed.disconnect(_on_button_pressed)
	button_alt.queue_free()
