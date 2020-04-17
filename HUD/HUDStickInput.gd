extends Control

onready var frame = $Frame
onready var stick = $StickPosition


func update_stick_input(input : Vector2):
	stick.rect_position = 0.5 * (rect_size - stick.rect_size) + 50 * input
