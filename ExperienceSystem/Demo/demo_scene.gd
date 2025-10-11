extends Node2D

func _ready() -> void:
	$Button.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	$ExperienceComponent.add_experience($SpinBox.value)
