class_name WeaponArea
extends WeaponBase

@export var area: Area2D

func attack() -> void:
	var bodies = area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemy"):
			body = body as Enemy
			var damage_value = damage * calculate_crit()
			body.health_node.damage(damage_value)
