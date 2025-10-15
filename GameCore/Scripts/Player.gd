extends CharacterBody2D
class_name Player

@export var move_speed: float = 240.0
@export var projectile_scene: PackedScene = preload("res://GameCore/Scenes/Projectile.tscn")
@export var fire_interval: float = 0.3

var _input_vec: Vector2 = Vector2.ZERO
@onready var health_node: HealthComponent = $Health
@onready var experience_node: ExperienceComponent = $ExperienceComponent
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var _fire_elapsed: float = 0.0
var _is_taking_damage: bool = false
var _damage_cooldown: float = 0.0
signal player_died

func _ready() -> void:
	# Força o player a ser visível
	visible = true
	
	add_to_group("player")
	_ensure_input_actions()
	# Conecta morte do HealthSystem -> die()
	health_node.status.died.connect(_on_health_died)
	# Conecta dano para tocar animação hurt
	health_node.status.health_changed.connect(_on_health_changed)

func _physics_process(delta: float) -> void:
	# Coleta input (WASD e setas)
	_input_vec = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if _input_vec.length_squared() > 1.0:
		_input_vec = _input_vec.normalized()
	velocity = _input_vec * move_speed
	move_and_slide()
	
	# Atualiza timer de dano
	if _damage_cooldown > 0:
		_damage_cooldown -= delta
		if _damage_cooldown <= 0:
			_is_taking_damage = false
	
	# Atualiza animação baseado no movimento
	_update_animation()

	# Disparo automático
	_fire_elapsed += delta
	if _fire_elapsed >= fire_interval:
		_fire_elapsed = 0.0
		_shoot()

func _update_animation() -> void:
	# Se está tomando dano, mantém animação hurt
	if _is_taking_damage:
		if animated_sprite.animation != "hurt":
			animated_sprite.play("hurt")
		return
	
	# Se está se movendo, toca "run", senão "idle"
	if _input_vec.length() > 0.1:
		animated_sprite.play("run")
		# Flip horizontal baseado na direção
		if _input_vec.x != 0:
			animated_sprite.flip_h = _input_vec.x < 0
	else:
		animated_sprite.play("idle")

func _shoot() -> void:
	if projectile_scene == null:
		return
	var p: Node2D = projectile_scene.instantiate()
	var mouse_gpos: Vector2 = get_global_mouse_position()
	var dir: Vector2 = (mouse_gpos - global_position).normalized()
	p.global_position = global_position
	if p.has_method("set_direction"):
		p.call("set_direction", dir)
	# opcional: alinhar visual com a direção
	if p.has_method("set_rotation"):
		p.set("rotation", dir.angle())
	get_tree().current_scene.add_child(p)

func _ensure_input_actions() -> void:
	# Cria os mapeamentos se não existirem (Godot 4)
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
	# Evita duplicar o mesmo evento
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
	# Toca animação hurt quando a vida muda (dano ou cura)
	_is_taking_damage = true
	_damage_cooldown = 0.3  # Mantém animação hurt por 0.3s

func die() -> void:
	# Desativa física/entrada e colisões do player
	set_process(false)
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	
	# Toca animação de morte
	animated_sprite.play("death")
	
	# Espera a animação terminar antes de esconder
	await animated_sprite.animation_finished
	visible = false
	
	player_died.emit()

func add_experience(amount: int) -> void:
	if experience_node:
		experience_node.add_experience(amount)
