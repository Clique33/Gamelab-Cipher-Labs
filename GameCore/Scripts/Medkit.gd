extends Area2D
class_name Medkit

@export var heal_amount: float = 20.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		body_entered.connect(_on_body_entered)

	# toca animação idle no AnimatedSprite2D filho (estrutura: Area2D -> AnimatedSprite2D)
	if animated_sprite and animated_sprite.has_method("play"):
		animated_sprite.play("idle")

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		# tenta aplicar cura via node de saúde do player
		if body.has_method("get_health_node"):
			var ph = body.get_health_node()
			if ph:
				if ph.has_method("heal"):
					ph.heal(heal_amount)
				elif "CurrentHealth" in ph and "MaxHealth" in ph:
					ph.CurrentHealth = min(float(ph.CurrentHealth) + heal_amount, float(ph.MaxHealth))
		else:
			# fallback: se o player expõe health_node
			if "health_node" in body:
				var ph2 = body.health_node
				if ph2 and ph2.has_method("heal"):
					ph2.heal(heal_amount)
		# animação/efeito poderia ser tocado aqui
		queue_free()
