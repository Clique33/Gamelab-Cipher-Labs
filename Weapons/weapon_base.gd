class_name WeaponBase
extends Node2D

@export var cooldown: float
@export var damage: float
@export var crit_chance: float
@export var crit_multiplier: float
var curr_cooldown: float = 0.0

func _process(delta: float) -> void:
	curr_cooldown -= delta
	if curr_cooldown <= 0:
		curr_cooldown += cooldown
		attack()

func attack() -> void:
	pass

func is_crit() -> bool:
	return randf() > crit_chance

func calculate_crit() -> float:
	if is_crit():
		return 1 + crit_multiplier
	return 1
