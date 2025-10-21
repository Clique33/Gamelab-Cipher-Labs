class_name WeaponArea
extends WeaponBase

@export var area: Area2D

@export_group("Shotgun Falloff")
@export var max_damage_distance: float = 30.0 
@export var min_damage_distance: float = 150.0 
@export var max_damage_multiplier: float = 1.5
@export var min_damage_multiplier: float = 0.8
@export var muzzle_flash_path: NodePath = NodePath("weapon_visual/AnimatedSprite2D")
@export var shoot_path: NodePath = NodePath("ShootSoundShotgun")

func attack() -> void:
	# Garante que a variável 'area' (a hurt_box) é válida antes de atacar.
	if not is_instance_valid(area):
		return

	var bodies = area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemy"):
			
			var distance = global_position.distance_to(body.global_position)
			var proximity_factor = clamp(inverse_lerp(distance, min_damage_distance, max_damage_distance), 0.0, 1.0)
			var damage_multiplier = lerp(min_damage_multiplier, max_damage_multiplier, proximity_factor)
			var base_damage = damage * calculate_crit()
			var final_damage = base_damage * damage_multiplier
			
			for child in body.get_children():
				if child is HealthComponent:
					child.damage(final_damage)
					break
	# 3️⃣ Tocar animação de disparo se existir
	var muzzle_flash = get_node_or_null(muzzle_flash_path)
	if muzzle_flash:
		muzzle_flash.stop()        # Reinicia a animação
		muzzle_flash.visible = true
		muzzle_flash.play("default")
		muzzle_flash.connect("animation_finished", Callable(muzzle_flash, "hide"))
		
	var shoot_shotgun = get_node_or_null("ShootShotgunSound")
	if shoot_shotgun:
		shoot_shotgun.play()
