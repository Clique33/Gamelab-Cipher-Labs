extends Node2D

@export var enemy_scene: PackedScene = preload("res://GameCore/Scenes/Enemy.tscn")
@onready var player: Node2D = $Player
@onready var camera: Camera2D = $Camera2D

@export var spawn_radius: float = 320.0
@export var spawn_interval: float = 2.0

func _ready() -> void:
	if camera and player:
		camera.make_current()
		# Segue o player (em Godot 4, basta current = true e mesmo nó, mas manter claro):
		camera.position = player.position
	_spawn_loop()

func _process(delta: float) -> void:
	if camera and player:
		camera.position = player.position

func _spawn_loop() -> void:
	# simples loop assíncrono de spawn
	while true:
		await get_tree().create_timer(spawn_interval).timeout
		_spawn_enemy()

func _spawn_enemy() -> void:
	if enemy_scene == null:
		return
	var e := enemy_scene.instantiate()
	var angle := randf() * TAU
	var offset := Vector2.RIGHT.rotated(angle) * spawn_radius
	e.global_position = player.global_position + offset
	add_child(e)
