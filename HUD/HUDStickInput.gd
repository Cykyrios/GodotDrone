extends Control

onready var stick = $StickPosition


func _ready():
	pass # Replace with function body.


func update_stick_input(input : Vector2):
	stick.rect_position = Vector2(45, 45) + 50 * input
