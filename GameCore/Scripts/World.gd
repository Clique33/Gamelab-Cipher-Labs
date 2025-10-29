extends Node2D

@export var enemy_scene: PackedScene = preload("res://GameCore/Scenes/Enemy.tscn")
@export var enemy_scenes: Array[PackedScene] = []
@export var enemy_data_list: Array[EnemyData] = []
@onready var player: Player = $Player
@onready var camera: Camera2D = $Camera2D

@onready var map_scene: Node = $Mapa
@onready var tilemap_layer: Node = $Mapa.get_node_or_null("TileMapLayer")

@export var spawn_radius: float = 150.0
@export var spawn_margin: float = 90.0 # extra distance outside camera view to spawn
@export var initial_spawn_interval: float = 1.0 # shorter default interval
@export var min_spawn_distance: float = 150.0 # don't spawn too close to player
@export var spawn_attempts: int = 12 # attempts to find a valid spawn position inside map
@export var min_spawn_interval: float = 0.25  # shorter minimum interval
@export var time_to_max_difficulty: float = 180.0 # seconds to reach max difficulty (faster difficulty ramp)

# Rare drop (configurável)
@export var rare_drop_scene: PackedScene = null
@export var rare_drop_chance: float = 0.05 # 5% chance when condition met
@export var rare_drop_every: int = 500 # check every N kills

signal game_won

var _kill_count: int = 0

var _elapsed_time: float = 0.0
var _debug_spawn_markers: Array = []
var _game_won_flag: bool = false
var _allow_spawns: bool = true

# Allow designers to assign popup scenes in the inspector instead of preloading constants
@export var VictoryPopupScene: PackedScene = null
@export var DeathPopupScene: PackedScene = null

func _ready() -> void:
	UpgradeManager.start_new_run()
	if camera and player:
		camera.make_current()
		camera.position = player.position
	
	# expose World via group for other nodes to find it reliably
	add_to_group("world")

	# Conecta o próprio signal para mostrar a popup quando vencer
	if not is_connected("game_won", Callable(self, "_on_game_won")):
		game_won.connect(_on_game_won)

	# Cria atalho de debug F9 para spawnar o item final
	"""if not InputMap.has_action("spawn_final"):
		InputMap.add_action("spawn_final")
		var ev := InputEventKey.new()
		ev.keycode = KEY_F9
		InputMap.action_add_event("spawn_final", ev)"""
	
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

	# Connect player death to show death popup
	if player and not player.is_connected("player_died", Callable(self, "_on_player_died")):
		player.player_died.connect(Callable(self, "_on_player_died"))

func _process(delta: float) -> void:
	if camera and player:
		camera.position = player.position

	# debug: pressionar F9 spawna o item final na posição do player
	if Input.is_action_just_pressed("spawn_final") and player != null:
		force_spawn_rare(player.global_position)

func _draw() -> void:
	# Draw temporary spawn markers (red ring with yellow center)
	for pos in _debug_spawn_markers:
		var local_p: Vector2 = to_local(pos)
		draw_circle(local_p, 14.0, Color(1, 0, 0, 0.6))
		draw_circle(local_p, 7.0, Color(1, 1, 0, 0.9))

func _spawn_loop() -> void:
	while is_inside_tree() and not _game_won_flag:
		if not _allow_spawns or get_tree() == null or get_tree().paused:
			if get_tree() == null or !is_inside_tree():
				return
			await get_tree().process_frame
			continue

		# --- Cálculo da dificuldade ---
		# Normaliza tempo entre 0 e 1
		var t: float = clamp(_elapsed_time / max(0.0001, time_to_max_difficulty), 0.0, 1.0)
		
		# Aplica curva exponencial para spawn rate: começa lento, acelera mais rápido depois
		var difficulty: float = pow(t, 1.5)  # ajuste o expoente para controlar progressão

		# Intervalo de spawn decresce com dificuldade (lerp exponencial)
		var current_interval: float = lerp(initial_spawn_interval, min_spawn_interval, difficulty)

		# Spawn timer
		await get_tree().create_timer(current_interval).timeout

		# Checa de novo se pode spawnar
		if not _allow_spawns or _game_won_flag or get_tree().paused:
			continue

		_elapsed_time += current_interval

		# --- Determina inimigo a spawnar com probabilidade dinâmica ---
		_spawn_enemy_with_difficulty(difficulty)


func _spawn_enemy_with_difficulty(difficulty: float) -> void:
	var r: float = randf()

	# Probabilidades de inimigos: fraco, médio, forte
	# Inimigos fortes aparecem mais cedo e aumentam continuamente
	var p_weak: float = clamp(lerp(0.7, 0.2, difficulty / (difficulty + 1)), 0.1, 0.7)
	var p_medium: float = clamp(lerp(0.9, 0.6, difficulty / (difficulty + 1)), 0.2, 0.9)
	# Resto será inimigo forte

	var idx: int = 0
	if r < p_weak:
		idx = 0
	elif r < p_medium:
		idx = 2
	else:
		idx = 1

	var base_data: Resource = null
	if idx >= 0 and idx < enemy_data_list.size():
		base_data = enemy_data_list[idx]

	# Instancia inimigo
	var chosen_scene: PackedScene = enemy_scenes[idx] if idx < enemy_scenes.size() else enemy_scene
	var e = chosen_scene.instantiate()

	# Escala stats com dificuldade de forma infinita
	if base_data:
		var data_copy = base_data.duplicate(true)
		var scale_factor: float = 1.0 + pow(difficulty, 1.5)  # escalada infinita exponencial

		if data_copy.has_method("set"):
			if "move_speed" in data_copy:
				data_copy.move_speed *= scale_factor
			if "touch_damage" in data_copy:
				data_copy.touch_damage *= scale_factor
			if "xp_amount" in data_copy:
				# XP cresce proporcionalmente aos stats
				data_copy.xp_amount = int(ceil(float(data_copy.xp_amount) * scale_factor))
			if "health_status" in data_copy and data_copy.health_status:
				var hs = data_copy.health_status.duplicate(true)
				if "MaxHealth" in hs:
					hs.MaxHealth *= scale_factor
					hs.CurrentHealth *= scale_factor
				data_copy.health_status = hs

		if "data" in e:
			e.data = data_copy

	# Determina spawn
	var spawn_pos = _find_valid_spawn_pos()
	if spawn_pos == Vector2.ZERO:
		spawn_pos = player.global_position + Vector2.RIGHT.rotated(randf() * TAU) * spawn_radius

	e.global_position = spawn_pos
	add_child(e)



func _spawn_enemy(difficulty: float = 0.0) -> void:
	# Prevent spawning if the game has been won and spawns are disabled
	if not _allow_spawns or _game_won_flag:
		return
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

	# tenta encontrar uma posição válida de spawn dentro do TileMap (próxima do player)
	var spawn_pos: Vector2 = _find_valid_spawn_pos()
	# se falhar, cair para o comportamento antigo (spawn em anel ao redor do player)
	if spawn_pos == Vector2.ZERO:
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
		spawn_pos = player.global_position + offset

	# Debug info to help locate spawned enemies if they are not visible
	var scene_path := "(unknown)"
	if chosen_scene and chosen_scene.resource_path:
		scene_path = chosen_scene.resource_path

	e.global_position = spawn_pos
	add_child(e)


func _is_point_inside_map_world_rect(point: Vector2) -> bool:
	# if we don't have a TileMap, allow by default
	if tilemap_layer == null:
		return true
	# Convert world point to tile cell
	var cell: Vector2i = Vector2i()
	if tilemap_layer.has_method("world_to_map"):
		cell = tilemap_layer.world_to_map(point) as Vector2i
	else:
		# Fallback: convert to map local space and use an assumed tile size (32)
		var local_p: Vector2 = tilemap_layer.to_local(point)
		var tile_size: Vector2 = Vector2(32, 32)
		cell = Vector2i(floor(local_p.x / tile_size.x), floor(local_p.y / tile_size.y))
	# If the TileMap provides used rect info, check bounds
	if tilemap_layer.has_method("get_used_rect"):
		var ur: Rect2i = tilemap_layer.get_used_rect() as Rect2i
		if not ur.has_point(cell):
			return false
	# Check if the cell has a tile (non-empty). Use get_cell if available.
	if tilemap_layer.has_method("get_cell"):
		var tid_val = tilemap_layer.get_cell(cell.x, cell.y)
		# get_cell can return different types; coerce to int safely
		var tid: int = int(tid_val)
		return tid >= 0
	return true


func _find_valid_spawn_pos() -> Vector2:
	if player == null:
		return Vector2.ZERO
	# Try multiple attempts, preferring closer distances first
	for i in range(spawn_attempts):
		var t: float = float(i) / max(1, spawn_attempts - 1)
		var dist: float = lerp(min_spawn_distance, spawn_radius, t)
		var angle: float = randf() * TAU
		var candidate: Vector2 = player.global_position + Vector2.RIGHT.rotated(angle) * dist
		if _is_point_inside_map_world_rect(candidate):
			return candidate
	return Vector2.ZERO


func register_enemy_death(position: Vector2) -> void:
	# increment kill count and evaluate rare drop condition
	_kill_count += 1
	if rare_drop_every > 0 and _kill_count % rare_drop_every == 0:
		var r: float = randf()
		print("[World] Rare-drop check: kill_count=", _kill_count, " roll=", r, " threshold=", rare_drop_chance)
		if r <= rare_drop_chance and rare_drop_scene != null and not _game_won_flag:
			var drop = rare_drop_scene.instantiate()
			if drop:
				drop.global_position = position
				get_tree().current_scene.call_deferred("add_child", drop)
				print("[World] Rare drop spawned at ", position)


func _on_game_won() -> void:
	# Stop spawning and show popup with statistics (don't pause the SceneTree so UI remains interactive)
	_game_won_flag = true
	_allow_spawns = false
	# If a VictoryPopup node exists in the current scene, reuse it (the designer placed it)
	var current = get_tree().current_scene
	# search recursively for a node named VictoryPopup (designer might place it under different parents)
	var existing = null
	if current:
		# Prefer a node that exposes play_victory_particles (designer may have renamed the node)
		existing = null
		for node in current.get_children():
			var found = _find_node_with_method(node, "play_victory_particles")
			if found:
				existing = found
				break
	if existing and existing is Control:
		print("[World] Found existing VictoryPopup at path: ", existing.get_path())
		# ensure it's visible and on top
		# If popup is parented under a Camera2D or Node2D, reparent it to a UI CanvasLayer so it's in screen space
		var ui_parent = _get_ui_parent()
		if existing.get_parent() != ui_parent:
			# reparent safely
			var old = existing.get_parent()
			if old:
				old.remove_child(existing)
				ui_parent.add_child(existing)
		# now ensure visibility and stacking
		existing.visible = true
		if existing.has_method("set_stats"):
			existing.set_stats(_kill_count, _elapsed_time)
		if existing.has_method("play_victory_particles"):
				existing.play_victory_particles()
		# bring to front
		if existing.has_method("raise"):
			existing.raise()
		return
	# Fallback: instantiate predefined popup scene
	if VictoryPopupScene:
		var popup = VictoryPopupScene.instantiate()
		if popup:
			# passa estatísticas
			if popup.has_method("set_stats"):
				popup.set_stats(_kill_count, _elapsed_time)
			# parent to UI layer so it's not affected by camera
			var ui_parent = _get_ui_parent()
			ui_parent.call_deferred("add_child", popup)


func force_spawn_rare(position: Vector2) -> void:
	# For testing: spawn the rare drop regardless of counters
	if rare_drop_scene == null:
		return
	var drop = rare_drop_scene.instantiate()
	if drop:
		drop.global_position = position
		get_tree().current_scene.call_deferred("add_child", drop)


func _find_node_in_tree(root: Node, name: String) -> Node:
	if root.name == name:
		return root
	for child in root.get_children():
		if child and child is Node:
			var found = _find_node_in_tree(child, name)
			if found:
				return found
	return null


func _find_node_with_method(root: Node, method_name: String) -> Node:
	if root and root is Node:
		if root.has_method(method_name):
			return root
		for child in root.get_children():
			if child and child is Node:
				var f = _find_node_with_method(child, method_name)
				if f:
					return f
	return null


func _get_ui_parent() -> Node:
	# Returns an existing CanvasLayer or creates one under the current scene root
	var current = get_tree().current_scene
	if current == null:
		# fallback to the scene root viewport which is a Node
		return get_tree().root
	# Common names
	var ui = current.get_node_or_null("CanvasLayer")
	if ui:
		return ui
	ui = current.get_node_or_null("UI")
	if ui and ui is CanvasLayer:
		return ui
	# search children for CanvasLayer
	for child in current.get_children():
		if child and child is CanvasLayer:
			return child
	# create one and add it to root
	var new_ui := CanvasLayer.new()
	new_ui.name = "CanvasLayer"
	current.add_child(new_ui)
	return new_ui


func _on_player_died() -> void:
	# Player died: stop spawning and show DeathPopup (if present) with stats
	_allow_spawns = false
	_game_won_flag = true
	# try to find a DeathPopup in the current scene
	var current = get_tree().current_scene
	var existing = null
	if current:
		for node in current.get_children():
			var found = _find_node_with_method(node, "play_death_effects")
			if found:
				existing = found
				break
	if existing and existing is Control:
		var ui_parent = _get_ui_parent()
		if existing.get_parent() != ui_parent:
			var old = existing.get_parent()
			if old:
				old.remove_child(existing)
			ui_parent.add_child(existing)
		if existing.has_method("set_stats"):
			existing.set_stats(_kill_count, _elapsed_time)
		if existing.has_method("play_death_effects"):
			existing.play_death_effects()
		if existing.has_method("raise"):
			existing.raise()
		return
	# fallback: use exported DeathPopupScene assigned in the inspector
	if DeathPopupScene:
		var popup = DeathPopupScene.instantiate()
		if popup:
			if popup.has_method("set_stats"):
				popup.set_stats(_kill_count, _elapsed_time)
			var ui_parent = _get_ui_parent()
			ui_parent.call_deferred("add_child", popup)
	else:
		push_warning("DeathPopupScene not assigned on World node; cannot show death popup fallback.")
