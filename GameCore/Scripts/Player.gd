extends CharacterBody2D
class_name Player

@export var move_speed: float = 240.0
@export var projectile_scene: PackedScene = preload("res://GameCore/Scenes/Projectile.tscn")

# --- STATS DA ARMA BÁSICA ---
@export var cooldown: float = 1.5 
@export var damage: float = 10.0
@export var crit_chance: float = 0.05
@export var crit_multiplier: float = 0.5
# --- FIM STATS ---

# --- NOVA VARIÁVEL PARA O MEDKIT ---
# Adicionamos esta variável com um valor padrão de 1.0 (100% de cura).
# Agora o UpgradeManager tem o que ler e multiplicar.
@export var medkit_heal_multiplier: float = 1.0
# --- FIM DA NOVA VARIÁVEL ---

var _input_vec: Vector2 = Vector2.ZERO
@onready var health_node: HealthComponent = $Health
@onready var experience_node: ExperienceComponent = $ExperienceComponent
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var _fire_elapsed: float = 0.0
var _is_taking_damage: bool = false
var _damage_cooldown: float = 0.0
signal player_died

@onready var detection_area: Area2D = $DetectionArea
var nearest_enemy: Node2D = null

func _ready() -> void:
	visible = true
	add_to_group("player")
	_ensure_input_actions()
	health_node.status.died.connect(_on_health_died)
	health_node.status.health_changed.connect(_on_health_changed)
	if UpgradeManager:
		UpgradeManager.register_player(self)

func _physics_process(delta: float) -> void:
	_find_nearest_enemy()
	_aim_upgrade_weapons()

	_input_vec = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if _input_vec.length_squared() > 1.0:
		_input_vec = _input_vec.normalized()
	velocity = _input_vec * move_speed
	move_and_slide()
	
	if _damage_cooldown > 0:
		_damage_cooldown -= delta
		if _damage_cooldown <= 0:
			_is_taking_damage = false
	
	_update_animation()

	_fire_elapsed += delta
	if _fire_elapsed >= cooldown:
		_fire_elapsed = 0.0
		_shoot()

func _update_animation() -> void:
	if _is_taking_damage:
		if animated_sprite.animation != "hurt":
			animated_sprite.play("hurt")
		return
	
	if _input_vec.length() > 0.1:
		animated_sprite.play("run")
		if _input_vec.x != 0:
			animated_sprite.flip_h = _input_vec.x < 0
	else:
		animated_sprite.play("idle")

func _shoot() -> void:
	if projectile_scene == null or nearest_enemy == null or not is_instance_valid(nearest_enemy):
		return
		
	var p = projectile_scene.instantiate()
	
	if p is Projectile:
		p.damage = damage * calculate_crit()
	
	var dir: Vector2 = (nearest_enemy.global_position - global_position).normalized()
	
	p.global_position = global_position
	if p.has_method("set_direction"):
		p.call("set_direction", dir)
	if p.has_method("set_rotation"):
		p.set("rotation", dir.angle())
	get_tree().current_scene.add_child(p)

func is_crit() -> bool:
	return randf() > crit_chance

func calculate_crit() -> float:
	if is_crit():
		return 1 + crit_multiplier
	return 1

# --- FUNÇÃO ATUALIZADA ---
func _aim_upgrade_weapons() -> void:
	var target_rotation := global_rotation
	var has_target: bool = false # Adiciona uma flag para saber se há um alvo
	
	if nearest_enemy != null and is_instance_valid(nearest_enemy):
		var dir: Vector2 = (nearest_enemy.global_position - global_position).normalized()
		target_rotation = dir.angle()
		has_target = true # Define a flag como verdadeira se encontrou um inimigo

	for weapon in get_tree().get_nodes_in_group("weapon"):
		if weapon.get_parent() == self and weapon is Node2D:
			weapon.global_rotation = target_rotation
			
			# A MUDANÇA PRINCIPAL:
			# Ativa ou desativa o processamento (_process) da arma.
			# Se não há alvo (has_target = false), o _process da arma para,
			# o que impede seu cooldown de contar e o attack() de ser chamado.
			weapon.set_process(has_target)
# --- FIM DA ATUALIZAÇÃO ---

func _find_nearest_enemy() -> void:
	if detection_area == null:
		return
		
	var bodies = detection_area.get_overlapping_bodies()
	var min_dist_sq = INF
	nearest_enemy = null 

	for body in bodies:
		if body.is_in_group("enemy"):
			var dist_sq = global_position.distance_squared_to(body.global_position)
			if dist_sq < min_dist_sq:
				min_dist_sq = dist_sq
				nearest_enemy = body

# ... (O resto das suas funções _ensure_input_actions, die, etc. permanecem iguais) ...
func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("debug_level_up"):
		if UpgradeManager:
			print("DEBUG: Forçando a tela de upgrade!")
			UpgradeManager.on_player_leveled_up(0)
			get_viewport().set_input_as_handled()
			
func _ensure_input_actions() -> void:
	_ensure_action_key("move_up", KEY_W)
	_ensure_action_key("move_up", KEY_UP)
	_ensure_action_key("move_down", KEY_S)
	_ensure_action_key("move_down", KEY_DOWN)
	_ensure_action_key("move_left", KEY_A)
	_ensure_action_key("move_left", KEY_LEFT)
	_ensure_action_key("move_right", KEY_D)
	_ensure_action_key("move_right", KEY_RIGHT)
	_ensure_action_mouse("shoot", MOUSE_BUTTON_LEFT)

func _ensure_action_key(action: StringName, keycode: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventKey.new()
	ev.keycode = keycode
	for e in InputMap.action_get_events(action):
		if e is InputEventKey and e.keycode == keycode:
			return
	InputMap.action_add_event(action, ev)

func _ensure_action_mouse(action: StringName, button_index: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = button_index
	for e in InputMap.action_get_events(action):
		if e is InputEventMouseButton and e.button_index == button_index:
			return
	InputMap.action_add_event(action, ev)

func _on_health_died() -> void:
	die()

func get_health_node() -> HealthComponent:
	return health_node

func _on_health_changed(new_health: float) -> void:
	_is_taking_damage = true
	_damage_cooldown = 0.3

func die() -> void:
	set_process(false)
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	animated_sprite.play("death")
	await animated_sprite.animation_finished
	visible = false
	player_died.emit()

func add_experience(amount: int) -> void:
	if experience_node:
		experience_node.add_experience(amount)
