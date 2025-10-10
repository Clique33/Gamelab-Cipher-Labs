class_name WeaponProjectile
extends WeaponBase


@export var origin: Node2D
@export var projectile_scene: PackedScene
@export var is_mouse_direction: bool

func attack() -> void:
	var instance = projectile_scene.instantiate()
	if instance is Projectile:
		instance.damage = damage * calculate_crit()
		var dir = calculate_mouse_direction() if is_mouse_direction else calculate_random_direction()
		instance.set_direction(dir)
		instance.global_rotation = dir.angle()
		origin.add_child(instance)

func calculate_random_direction() -> Vector2:
	var angle := randf() * TAU
	return Vector2(cos(angle), sin(angle))

func calculate_mouse_direction() -> Vector2:
	var mouse_gpos: Vector2 = get_global_mouse_position()
	var dir: Vector2 = (mouse_gpos - global_position).normalized()
	return dir
