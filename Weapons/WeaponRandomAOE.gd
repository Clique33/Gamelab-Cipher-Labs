class_name WeaponRandomAOE
extends WeaponBase

@export var aoe_scene: PackedScene # <--- Arraste sua RandomCircleAOE.tscn aqui
@export var spawn_radius_min: float = 50.0  # Mínimo de pixels do player
@export var spawn_radius_max: float = 300.0 # Máximo de pixels do player

func attack() -> void:
	if aoe_scene == null:
		print("WeaponRandomAOE: A cena 'aoe_scene' não foi definida no Inspector!")
		return

	# 1. Instancia a cena da explosão
	var instance = aoe_scene.instantiate()
	
	# A verificação agora vai funcionar
	if not instance is RandomCircleAOE:
		return

	# 2. Calcula uma posição aleatória
	var random_angle = randf() * TAU
	var random_distance = randf_range(spawn_radius_min, spawn_radius_max)
	var offset = Vector2.RIGHT.rotated(random_angle) * random_distance
	var spawn_position = global_position + offset

	# 3. Configura e posiciona a explosão
	instance.damage = damage * calculate_crit()
	instance.global_position = spawn_position

	# 4. Adiciona a explosão à cena principal
	get_tree().current_scene.add_child(instance)
	
	# --- 5. Tocar som da explosão ---
	if instance.has_node("AudioStreamPlayer2D"): # se você tiver um AudioStreamPlayer2D dentro da cena da explosão
		var audio = instance.get_node("AudioStreamPlayer2D") as AudioStreamPlayer2D
		audio.play()
