extends Resource
class_name HealthStatus


signal health_changed(new_health: float)
signal max_health_changed(new_max_health: float)
signal died()

@export var MaxHealth: float:
	set(value):
		MaxHealth = value
		max_health_changed.emit(value)
@export var CurrentHealth: float:
	set(value):
		CurrentHealth = min(value, MaxHealth)
		health_changed.emit(value)
var Invulnerable: bool = false

func damage(value: float):
	if Invulnerable:
		return
	CurrentHealth -= value
	if CurrentHealth <= 0:
		died.emit()
