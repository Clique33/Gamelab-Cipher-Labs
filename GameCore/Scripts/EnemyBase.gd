extends CharacterBody2D
class_name EnemyBase

# -----------------------------
# Dados gerais
# -----------------------------
@export var data: EnemyData = null
@export var faces_right_by_default := true

# -----------------------------
# Referências de nós
# -----------------------------
@onready var health_node: HealthComponent = $Health
@onready var anim_node: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_area: Area2D = $DamageArea

# -----------------------------
# Controle interno
# -----------------------------
var player: Node2D = null
var _touching_player: bool = false
var _touch_elapsed: float = 0.0
var _last_dir_x: float = 1.0
var _is_moving: bool = false
var _is_dead: bool = false

# -----------------------------
# Funções auxiliares
# -----------------------------
func _apply_data() -> void:
	if not data:
		return
	if health_node and data.health_status:
		health_node.initial_status = data.health_status
	
	# --- CORREÇÃO CRUCIAL ---
	# O inimigo existe na camada 2.
	collision_layer = 2 
	# O inimigo SÓ colide com a camada 1 (paredes/chão).
	# Ele vai ignorar a camada 2 (outros inimigos) e a camada 3 (jogador).
	# --- FIM DA CORREÇÃO ---


func _update_sprite_flip() -> void:
	if not anim_node:
		return
	var facing_left: bool = (_last_dir_x > 0.0)
	if not faces_right_by_default:
		facing_left = not facing_left
	anim_node.flip_h = facing_left

func _play_run_animation() -> void:
	if anim_node.animation != "run":
		anim_node.animation = "run"
		anim_node.play()

func _play_idle_animation() -> void:
	if anim_node.animation != "idle":
		anim_node.animation = "idle"
		anim_node.play()

func _play_death_animation() -> void:
	if anim_node.animation != "death":
		anim_node.animation = "death"
		anim_node.play()

func _update_animation() -> void:
	if not anim_node:
		return
	if _is_moving:
		if anim_node.sprite_frames and anim_node.sprite_frames.has_animation("run"):
			anim_node.animation = "run"
			anim_node.play()
		else:
			print("[EnemyBase] No 'run' animation found!")
	else:
		if anim_node.sprite_frames and anim_node.sprite_frames.has_animation("idle"):
			anim_node.animation = "idle"
			anim_node.play()
		else:
			print("[EnemyBase] No 'idle' animation found!")


# -----------------------------
# Ready
# -----------------------------
func _ready() -> void:
	add_to_group("enemy")
	_set_player_ref()
	set_physics_process(true)
	_apply_data()

	# Conecta sinal de morte
	if health_node and not health_node.is_connected("died", Callable(self, "_on_died")):
		health_node.died.connect(_on_died)

	# Esconde barra de vida
	if health_node and health_node.ui:
		health_node.ui.visible = false

	# Conecta sinais do DamageArea
	if damage_area:
		if not damage_area.is_connected("body_entered", Callable(self, "_on_damage_body_entered")):
			damage_area.body_entered.connect(_on_damage_body_entered)
		if not damage_area.is_connected("body_exited", Callable(self, "_on_damage_body_exited")):
			damage_area.body_exited.connect(_on_damage_body_exited)

# -----------------------------
# Processamento de movimento
# -----------------------------
func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	if not is_instance_valid(player):
		_set_player_ref()
		_play_idle_animation()
		return

	# Dano por contato periódico
	if _touching_player:
		_touch_elapsed += delta
		var touch_interval := 0.5
		if data and data.touch_interval != null:
			touch_interval = float(data.touch_interval)
		if _touch_elapsed >= touch_interval:
			_touch_elapsed = 0.0
			_apply_touch_damage()

	# Movimento em direção ao player
	var dir: Vector2 = Vector2.ZERO
	var stop_distance: float = 20.0
	if data and data.stop_distance != null:
		stop_distance = float(data.stop_distance)

	var to_player: Vector2 = player.global_position - global_position
	if to_player.length() > stop_distance:
		dir = to_player.normalized()
		if dir.x != 0:
			_last_dir_x = dir.x

	var move_speed: float = 180.0
	if data and data.move_speed != null:
		move_speed = float(data.move_speed)

	velocity = dir * move_speed
	move_and_slide()

	# Atualiza estado de movimento e animação
	_is_moving = velocity.length() > 0.1
	_update_sprite_flip()
	_update_animation()

# -----------------------------
# Referência ao player
# -----------------------------
func _set_player_ref() -> void:
	var plist := get_tree().get_nodes_in_group("player")
	player = plist[0] if plist.size() > 0 else null

# -----------------------------
# Dano por toque via DamageArea
# -----------------------------
func _apply_touch_damage() -> void:
	if not player or not is_instance_valid(player):
		return
	var dmg: float = 5.0
	if data and data.touch_damage != null:
		dmg = float(data.touch_damage)

	if player.has_method("get_health_node"):
		var ph = player.get_health_node()
		if ph:
			ph.damage(dmg)
	elif "health_node" in player:
		player.health_node.damage(dmg)

func _on_damage_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_touching_player = true
		_apply_touch_damage()

func _on_damage_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_touching_player = false
		_touch_elapsed = 0.0

# -----------------------------
# Morte do inimigo
# -----------------------------
func _on_died() -> void:
	if _is_dead:
		return
	_is_dead = true
	set_physics_process(false)
	# Desativa a colisão completamente ao morrer
	collision_layer = 0
	collision_mask = 0
	velocity = Vector2.ZERO
	
	_spawn_xp_orb()

	var worlds: Array = get_tree().get_nodes_in_group("world")
	if worlds.size() > 0:
		var world = worlds[0]
		if world and world.has_method("register_enemy_death"):
			world.register_enemy_death(global_position)

	if data and data.drop_life_scene and data.drop_life_chance > 0.0:
		var r: float = randf()
		if r <= data.drop_life_chance:
			var drop = data.drop_life_scene.instantiate()
			if drop:
				drop.global_position = global_position
				if "heal_amount" in drop:
					drop.heal_amount = data.drop_life_amount
				elif drop.has_method("set_heal_amount"):
					drop.set_heal_amount(data.drop_life_amount)
				get_tree().current_scene.call_deferred("add_child", drop)
	
	if anim_node:
		_play_death_animation()
		await anim_node.animation_finished
	
	queue_free()

# -----------------------------
# XP drop
# -----------------------------
func _spawn_xp_orb() -> void:
	if not data or not data.xp_orb_scene:
		return
	var orb = data.xp_orb_scene.instantiate()
	if orb:
		orb.global_position = global_position
		orb.xp_value = data.xp_amount
		get_tree().current_scene.call_deferred("add_child", orb)
