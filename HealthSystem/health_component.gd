extends Node2D
class_name HealthComponent

signal died()

const GRAY_HEALTH_DELAY = 0.5

@export var initial_status: HealthStatus
var status: HealthStatus
@onready var current_ui: ProgressBar = $UI/current_bar
@onready var gray_ui: ProgressBar = $UI/gray_health
@onready var ui: Control = $UI

func damage(value: float) -> void:
	status.damage(value)

# API esperada: take_damage/current_health

func _ready() -> void:
	# initializes the health UI with the current health status
	status = initial_status.duplicate()
	current_ui.max_value = status.MaxHealth
	current_ui.value = status.CurrentHealth
	gray_ui.max_value = status.MaxHealth
	gray_ui.value = status.CurrentHealth
	status.health_changed.connect(ui.handle_change)
	status.died.connect(_on_died)

func _on_died():
	died.emit()
