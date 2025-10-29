extends WeaponBase
class_name machine_gun

@export var origin: Node2D
@export var projectile_scene: PackedScene
@export var burst_count: int = 3      # quantidade de tiros na rajada
@export var burst_delay: float = 0.1  # intervalo entre os tiros

var can_attack: bool = true

func attack() -> void:
	if not can_attack:
		return
	
	can_attack = false
	# Inicia a rajada
	_burst()

# Função async separada para disparar a rajada
func _burst() -> void:
	for i in burst_count:
		_spawn_projectile()
		await get_tree().create_timer(burst_delay).timeout  # espera entre os tiros
	await get_tree().create_timer(cooldown).timeout       # espera o cooldown
	can_attack = true

# Função que instancia o projétil
func _spawn_projectile() -> void:
	var instance = projectile_scene.instantiate()
	if instance is Projectile:
		instance.damage = damage * calculate_crit()
		
		var dir = Vector2.RIGHT.rotated(global_rotation)
		instance.set_direction(dir)
		instance.global_rotation = dir.angle()
		instance.global_position = origin.global_position
		
		get_tree().current_scene.add_child(instance)
