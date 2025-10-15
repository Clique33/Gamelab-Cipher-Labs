class_name WeaponBase
extends Upgrade


@export var cooldown: float
@export var damage: float
@export var crit_chance: float
@export var crit_multiplier: float
var curr_cooldown: float = 0.0
var active: bool = false

@export_group("upgrades")
@export var damage_scale_fixed: float
@export var damage_scale_multiplier: float
@export_range(0.0, 0.8, 0.001) var cooldown_scale: float

func _process(delta: float) -> void:
	if active:
		curr_cooldown -= delta
		if curr_cooldown <= 0:
			curr_cooldown = cooldown
			attack()

func attack() -> void:
	pass

func is_crit() -> bool:
	return randf() > crit_chance

func calculate_crit() -> float:
	if is_crit():
		return 1 + crit_multiplier
	return 1

func upgrade() -> void:
	damage *= (1 + damage_scale_multiplier)
	damage += damage_scale_fixed
	cooldown *= (1 - cooldown_scale)
