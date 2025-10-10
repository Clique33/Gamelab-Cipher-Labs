class_name Enemy
extends CharacterBody2D

@export var move_speed: float = 180.0
@export var stop_distance: float = 20.0
@export var touch_damage: float = 5.0
@export var touch_interval: float = 0.5
@onready var player: Player = null
@onready var health_node: HealthComponent = $Health
var _touching_player: bool = false
var _touch_elapsed: float = 0.0

func _ready() -> void:
	add_to_group("enemy")
	_set_player_ref()
	set_physics_process(true)
	# Se tiver componente de vida, reagir à morte
	health_node.died.connect(_on_died)
	# Esconde a UI do Health para inimigos
	health_node.ui.visible = false

func _physics_process(delta: float) -> void:
	# Dano por contato com intervalo
	if _touching_player:
		_touch_elapsed += delta
		if _touch_elapsed >= touch_interval:
			_touch_elapsed = 0.0
			_apply_touch_damage()

	if player == null or player is not Player:
		_set_player_ref()
		velocity = Vector2.ZERO
		return
	var to_player: Vector2 = (player.global_position - global_position)
	var dist := to_player.length()
	var dir: Vector2 = Vector2.ZERO
	if dist > stop_distance:
		dir = to_player.normalized()
	velocity = dir * move_speed
	move_and_slide()

func _set_player_ref() -> void:
	var plist := get_tree().get_nodes_in_group("player")
	if plist.size() > 0:
		player = plist[0]
	else:
		player = null

func _on_damage_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_touching_player = true
		# aplica dano imediato na entrada
		_apply_touch_damage()

func _on_damage_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_touching_player = false
		_touch_elapsed = 0.0

func _apply_touch_damage() -> void:
	if not player or not is_instance_valid(player):
		return
	# Procura o Health do player e aplica dano
	if player:
		player.health_node.damage(touch_damage)

func _on_died() -> void:
	set_physics_process(false)
	velocity = Vector2.ZERO
	queue_free()
