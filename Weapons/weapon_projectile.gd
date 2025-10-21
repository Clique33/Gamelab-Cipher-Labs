class_name WeaponProjectile
extends WeaponBase

@export var origin: Node2D
@export var projectile_scene: PackedScene
# @export var is_mouse_direction: bool # REMOVIDO [cite: 13]

func attack() -> void:
	var instance = projectile_scene.instantiate()
	if instance is Projectile:
		instance.damage = damage * calculate_crit()
		
		# MUDANÇA: Dispara na direção em que a arma está virada (global_rotation)
		var dir = Vector2.RIGHT.rotated(global_rotation)
		
		instance.set_direction(dir)
		instance.global_rotation = dir.angle()
		
		# MUDANÇA: Define a Posição Global e adiciona à cena principal
		# Isso evita que o projétil gire com a arma após ser disparado
		instance.global_position = origin.global_position
		get_tree().current_scene.add_child(instance)

# --- FUNÇÕES REMOVIDAS --- [cite: 13]
# func calculate_random_direction() -> Vector2: ...
# func calculate_mouse_direction() -> Vector2: ...
# --- FIM REMOVIDAS ---
