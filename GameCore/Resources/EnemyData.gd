extends Resource
class_name EnemyData

# Resource que guarda stats de um inimigo para reutilização e edição no inspector.
@export var display_name: String = "Enemy"
@export var health_status: Resource = null # HealthStatus (arquivo .tres) - pode ser null e o EnemyBase duplicará/fallback
@export var move_speed: float = 180.0
@export var stop_distance: float = 20.0
@export var touch_damage: float = 5.0
@export var touch_interval: float = 0.5
@export var xp_amount: int = 1
@export var xp_orb_scene: PackedScene = preload("res://GameCore/Scenes/XPOrb.tscn")
@export var sprite_scene: PackedScene = null # opcional: cena com AnimatedSprite2D/AnimatedSprite
@export var collision_layer: int = 1
@export var collision_mask: int = 1

# Add more fields as needed (drops, AI type, weapon, etc.)
