class_name ExperienceComponent
extends Node

signal leveled(new_level: int)
signal experience_gained(new_value: float)

@export var _data: ExperienceData
var level: int
var current_experience: float
var experience_to_level: float

func _ready() -> void:
	current_experience = 0
	level = 0
	level_up()

func _calculate_experience_to_level() -> float:
	return _data.experience_level_base * pow(_data.experience_level_growth, level - 1)

func add_experience(amount: float) -> void:
	current_experience += amount
	if current_experience >= experience_to_level:
		level_up()
	experience_gained.emit(current_experience)

func level_up() -> void:
	current_experience -= experience_to_level
	level += 1
	experience_to_level = _calculate_experience_to_level()
	leveled.emit(level)
