extends Node
# Adapter para a API esperada (take_damage/current_health) encaminhando para HealthSystem/health.gd

@export var health_node_path: NodePath = ^"../Health"

func _get_health_node() -> Node:
	var node := get_node_or_null(health_node_path)
	return node

func take_damage(value: float) -> void:
	var h = _get_health_node()
	if h and h.has_method("damage"):
		h.damage(value)
	elif h and h.get("status") != null:
		h.get("status").damage(value)

func get_current_health() -> float:
	var h = _get_health_node()
	if h and h.get("status") != null:
		return h.get("status").CurrentHealth
	return 0.0

# Propriedade-style para compatibilidade
var current_health: float:
	get:
		return get_current_health()
