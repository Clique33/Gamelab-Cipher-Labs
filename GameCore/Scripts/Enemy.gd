class_name Enemy
extends CharacterBody2D

@export var move_speed: float = 180.0
@export var stop_distance: float = 20.0
@export var touch_damage: float = 5.0
@export var touch_interval: float = 0.5
@export var xp_amount: int = 1
@export var xp_orb_scene: PackedScene = preload("res://GameCore/Scenes/XpOrb.tscn")
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
	var dist: float = to_player.length()
	var dir: Vector2 = Vector2.ZERO
	if dist > stop_distance:
		dir = to_player.normalized()
	velocity = dir * move_speed
	
	# Move sem colidir (atravessa o player)
	global_position += velocity * delta

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

func _spawn_xp_orb() -> void:
	if not xp_orb_scene:
		return
	
	var orb: XPOrb = xp_orb_scene.instantiate() as XPOrb
	if orb:
		orb.global_position = global_position
		orb.xp_value = xp_amount
		get_tree().current_scene.call_deferred("add_child",orb)

func _on_died() -> void:
	
	set_physics_process(false)
	set_collision_layer(0)
	set_collision_mask(0)
	velocity = Vector2.ZERO
	
	#Spawnar orbe de xp
	_spawn_xp_orb()
	
	queue_free()
