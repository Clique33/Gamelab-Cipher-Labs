extends Area2D

@export var speed: float = 560.0
@export var lifetime: float = 2.0
@export var damage: float = 10.0
var _dir: Vector2 = Vector2.RIGHT

func _ready() -> void:
	set_process(true)
	# Auto-destruir após lifetime
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func set_direction(d: Vector2) -> void:
	if d.length() > 0.01:
		_dir = d.normalized()
	rotation = _dir.angle()

func _process(delta: float) -> void:
	global_position += _dir * speed * delta

func _on_body_entered(body: Node) -> void:
	# Aplica dano se o corpo for inimigo e tiver Health
	if body.is_in_group("enemy"):
		var health_node = null
		if body.has_node("Health"):
			health_node = body.get_node("Health")
		if body.has_node("HealthAdapter"):
			var adapter = body.get_node("HealthAdapter")
			adapter.take_damage(damage)
	queue_free()
