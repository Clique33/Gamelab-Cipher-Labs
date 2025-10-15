extends Node2D

@export var enemy_scene: PackedScene = preload("res://GameCore/Scenes/Enemy.tscn")
@export var enemy_scenes: Array[PackedScene] = []
@export var enemy_data_list: Array[EnemyData] = []
@onready var player: Player = $Player
@onready var camera: Camera2D = $Camera2D

@export var spawn_radius: float = 320.0
@export var spawn_margin: float = 96.0 # extra distance outside camera view to spawn
@export var initial_spawn_interval: float = 1.0 # shorter default interval
@export var min_spawn_interval: float = 0.25  # shorter minimum interval
@export var time_to_max_difficulty: float = 180.0 # seconds to reach max difficulty (faster difficulty ramp)

var _elapsed_time: float = 0.0
var _debug_spawn_markers: Array = []

func _ready() -> void:
	if camera and player:
		camera.make_current()
		camera.position = player.position

	# If the level designer didn't populate the exported arrays in the inspector,
	# provide reasonable defaults so the spawner works out of the box.
	if enemy_scenes.is_empty():
		enemy_scenes = [
			preload("res://GameCore/Scenes/Enemy01.tscn"),
			preload("res://GameCore/Scenes/Enemy02.tscn"),
			preload("res://GameCore/Scenes/Enemy03.tscn"),
		]

	if enemy_data_list.is_empty():
		enemy_data_list = [
			preload("res://GameCore/Resources/Enemies/Droid01.tres"),
			preload("res://GameCore/Resources/Enemies/Droid02.tres"),
			preload("res://GameCore/Resources/Enemies/Droid03.tres"),
		]

	_spawn_loop()

func _process(delta: float) -> void:
	if camera and player:
		camera.position = player.position

func _draw() -> void:
	# Draw temporary spawn markers (red ring with yellow center)
	for pos in _debug_spawn_markers:
		var local_p: Vector2 = to_local(pos)
		draw_circle(local_p, 14.0, Color(1, 0, 0, 0.6))
		draw_circle(local_p, 7.0, Color(1, 1, 0, 0.9))

func _spawn_loop() -> void:
	# loop assíncrono de spawn que reduz o intervalo ao longo do tempo
	while true:
		var difficulty: float = clamp(_elapsed_time / max(0.0001, time_to_max_difficulty), 0.0, 1.0)
		var current_interval: float = lerp(initial_spawn_interval, min_spawn_interval, difficulty)
		await get_tree().create_timer(current_interval).timeout
		_elapsed_time += current_interval
		_spawn_enemy(difficulty)

func _spawn_enemy(difficulty: float = 0.0) -> void:
	if enemy_scene == null:
		return

	# decide qual tipo spawnar com base na dificuldade (probabilidades mudam ao longo do tempo)
	var r: float = randf()
	var p_weak: float = lerp(0.7, 0.4, difficulty) # chance de spawnar o inimigo fraco
	var p_medium: float = lerp(0.9, 0.8, difficulty) # cumulativa para o inimigo médio
	var idx: int = 0
	if r < p_weak:
		idx = 0 # Droid01 (fast/weak)
	elif r < p_medium:
		idx = 2 # Droid03 (balanced)
	else:
		idx = 1 # Droid02 (tank)

	var base_data: Resource = null
	if idx >= 0 and idx < enemy_data_list.size():
		base_data = enemy_data_list[idx]

	# choose which scene to instantiate: prefer per-variant scene list, fall back to single enemy_scene
	var chosen_scene: PackedScene = null
	if idx >= 0 and idx < enemy_scenes.size() and enemy_scenes[idx] != null:
		chosen_scene = enemy_scenes[idx]
	else:
		chosen_scene = enemy_scene

	var e := chosen_scene.instantiate()

	# antes de adicionar à cena, duplica e escala o EnemyData para subir dificuldade sem mutar o resource original
	if base_data:
		var data_copy = base_data.duplicate(true)
		# escala progressiva: até +80% em move_speed e dano ao chegar ao max
		var scale_factor: float = 1.0 + difficulty * 0.8
		if data_copy.has_method("set"):
			# tenta aplicar campos de forma genérica
			if "move_speed" in data_copy:
				data_copy.move_speed = float(data_copy.move_speed) * scale_factor
			if "touch_damage" in data_copy:
				data_copy.touch_damage = float(data_copy.touch_damage) * scale_factor
			if "xp_amount" in data_copy:
				data_copy.xp_amount = int(ceil(float(data_copy.xp_amount) * (1.0 + difficulty * 0.5)))
			# escalonando HealthStatus, se existir
			if "health_status" in data_copy and data_copy.health_status:
				var hs = data_copy.health_status.duplicate(true)
				if "MaxHealth" in hs:
					hs.MaxHealth = float(hs.MaxHealth) * scale_factor
					hs.CurrentHealth = float(hs.CurrentHealth) * scale_factor
				data_copy.health_status = hs

		# atribui o data duplicado à instância do inimigo (antes do _ready)
		if "data" in e:
			e.data = data_copy

	# posiciona e adiciona: spawn fora da visão do player/câmera
	var spawn_distance: float = spawn_radius
	if camera and get_viewport():
		var vp_size: Vector2 = get_viewport().get_visible_rect().size
		# account for camera zoom (Vector2)
		var view_half: Vector2 = vp_size * 0.5 * camera.zoom
		var max_half: float = max(view_half.x, view_half.y)
		spawn_distance = max(spawn_radius, max_half) + spawn_margin
	# Clamp spawn distance to avoid extreme positions (e.g., due to very large viewports or zoom)
	var MAX_SPAWN_DISTANCE: float = 2000.0
	spawn_distance = clamp(spawn_distance, spawn_radius, MAX_SPAWN_DISTANCE)
	var angle: float = randf() * TAU
	var offset := Vector2.RIGHT.rotated(angle) * spawn_distance
	var spawn_pos: Vector2 = player.global_position + offset

	# Debug info to help locate spawned enemies if they are not visible
	var scene_path := "(unknown)"
	if chosen_scene and chosen_scene.resource_path:
		scene_path = chosen_scene.resource_path

	e.global_position = spawn_pos
	add_child(e)
