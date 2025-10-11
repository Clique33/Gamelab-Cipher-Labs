class_name ExperienceUI
extends Control

@export var component: ExperienceComponent
@onready var bar: ProgressBar = $ExperienceBar
@onready var lvl_num: Label = $LevelNumber
@onready var exp_num: Label = $ExperienceBar/ExperienceNumber

func _ready() -> void:
	print("ExperienceUI: _ready() called")
	print("ExperienceUI: component = ", component)
	print("ExperienceUI: component path = ", component.get_path() if component else "NULL")
	print("ExperienceUI: bar = ", bar)
	bar.value = component.current_experience
	bar.max_value = component.experience_to_level
	lvl_num.text = str(component.level)
	_on_experience_gained(0)
	print("ExperienceUI: Connecting to component.leveled")
	component.leveled.connect(_on_leveled)
	print("ExperienceUI: Connecting to component.experience_gained")
	component.experience_gained.connect(_on_experience_gained)
	print("ExperienceUI: Signals connected!")
	bar.mouse_entered.connect(_on_bar_mouse_enter)
	bar.mouse_exited.connect(_on_bar_mouse_exit)

func _on_experience_gained(new_value: float) -> void:
	print("ExperienceUI: _on_experience_gained called with ", new_value)
	print("ExperienceUI: component.current_experience = ", component.current_experience)
	bar.value = new_value
	exp_num.text = "%.2f/%.2f" % [component.current_experience, component.experience_to_level]
	print("ExperienceUI: bar.value set to ", bar.value)
	
func _on_leveled(new_level: int) -> void:
	bar.max_value = component.experience_to_level
	lvl_num.text = str(new_level)

func _on_bar_mouse_enter() -> void:
	exp_num.visible = true
	
func _on_bar_mouse_exit() -> void:
	exp_num.visible = false
