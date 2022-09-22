extends Control


@onready var frame := $Frame
@onready var stick := $StickPosition


func update_stick_input(input: Vector2) -> void:
	stick.position = 0.5 * (size - stick.size) + 50 * input
