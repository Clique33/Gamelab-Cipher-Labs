extends Node2D


@onready var health = $Health
@onready var damage_amount = $SpinBox



func _on_button_pressed() -> void:

	health.damage(damage_amount.value)
