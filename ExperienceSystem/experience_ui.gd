class_name ExperienceUI
extends Control

@export var component: ExperienceComponent
@onready var bar: ProgressBar = $ExperienceBar
@onready var lvl_num: Label = $LevelNumber
@onready var exp_num: Label = $ExperienceBar/ExperienceNumber

func _ready() -> void:
	bar.value = component.current_experience
	bar.max_value = component.experience_to_level
	lvl_num.text = str(component.level)
	_on_experience_gained(0)
	component.leveled.connect(_on_leveled)
	component.experience_gained.connect(_on_experience_gained)
	bar.mouse_entered.connect(_on_bar_mouse_enter)
	bar.mouse_exited.connect(_on_bar_mouse_exit)

func _on_experience_gained(new_value: float) -> void:
	bar.value = new_value
	exp_num.text = "%.2f/%.2f" % [component.current_experience, component.experience_to_level]
	
func _on_leveled(new_level: int) -> void:
	bar.max_value = component.experience_to_level
	lvl_num.text = str(new_level)

func _on_bar_mouse_enter() -> void:
	exp_num.visible = true
	
func _on_bar_mouse_exit() -> void:
	exp_num.visible = false
