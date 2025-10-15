extends Area2D
class_name FinalDrop

func _ready() -> void:
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	# Debug: print who entered and collision layers/masks
	print("[FinalDrop] body_entered: ", body, " groups=", body.get_groups())
	if body.has_method("get"):
		# try to read collision layers/masks if available
		if "collision_layer" in body:
			print("[FinalDrop] body.collision_layer=", str(body.collision_layer))
		if "collision_mask" in body:
			print("[FinalDrop] body.collision_mask=", str(body.collision_mask))
	print("[FinalDrop] self.collision_layer=", str(collision_layer), " self.collision_mask=", str(collision_mask))

	if body.is_in_group("player"):
		# toca partículas de coleta, aguarda e então notifica o World
		if has_node("Particles"):
			var p = get_node("Particles") as CPUParticles2D
			p.emitting = true
			# if the particles have a material with lifetime, wait for that duration plus a small buffer
			var wait_time = 0.5
			if p.process_material and p.process_material.has_method("get"):
				# ParticlesMaterial exposes 'lifetime' property
				if "lifetime" in p.process_material:
					wait_time = float(p.process_material.lifetime) + 0.15
			await get_tree().create_timer(wait_time).timeout
		else:
			# fallback short delay
			await get_tree().create_timer(0.35).timeout
		# Notifica o World que o jogo foi vencido
		var worlds = get_tree().get_nodes_in_group("world")
		if worlds.size() > 0:
			var world = worlds[0]
			if world and world.has_signal("game_won"):
				world.emit_signal("game_won")
		# remove o drop
		queue_free()
