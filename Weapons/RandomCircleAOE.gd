class_name RandomCircleAOE
extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var damage: float = 10.0

func _ready() -> void:
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.play("default") 
	
	# --- MUDANÇA PRINCIPAL ---
	# Removemos o 'await' daqui.
	# Em vez disso, esperamos um curto período (0.05s) para garantir
	# que o servidor de física registrou a posição da área.
	# Isso é mais robusto que 'await physics_frame'.
	await get_tree().create_timer(0.05).timeout
	apply_area_damage()

func apply_area_damage() -> void:
	var bodies = get_overlapping_bodies()
	
	# --- DEBUG 1 ---
	# Isso nos diz quantos corpos a área encontrou.
	print("Bomba %s: Verificando dano. Corpos encontrados: %s" % [self.name, bodies.size()])

	if bodies.is_empty():
		print("Bomba Aleatória: Nenhum inimigo encontrado na área de explosão. Verifique as camadas de colisão.") 
		return # Adicionado para segurança

	for body in bodies:
		# --- DEBUG 2 ---
		# Isso nos diz o que foi encontrado e se está no grupo correto.
		print("Corpo encontrado: %s, está no grupo 'enemy'? %s" % [body.name, body.is_in_group("enemy")])
		
		if body.is_in_group("enemy"): 
			var health_found = false
			for child in body.get_children():
				if child is HealthComponent:
					# --- DEBUG 3 ---
					# Isso confirma que o dano está sendo enviado.
					print("HealthComponent encontrado! Aplicando %s de dano." % damage)
					child.damage(damage) 
					health_found = true
					break
			
			if not health_found:
				# --- DEBUG 4 ---
				# Isso nos alerta se o inimigo não tiver um HealthComponent.
				print("ERRO: Inimigo %s foi encontrado, mas não tem um HealthComponent!" % body.name)

func _on_animation_finished() -> void:
	queue_free()
