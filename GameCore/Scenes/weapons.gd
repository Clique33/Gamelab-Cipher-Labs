extends Node


var _weapons: Array[WeaponBase]
var _target_point: Vector2
@export var player: Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_update_target_point()

func _update_target_point() -> void:
	var enemies = get_tree().get_nodes_in_group("enemy") as Array[Enemy]
	_target_point = Vector2.INF
	for enemy in enemies:
		if _get_distance(_target_point) > _get_distance(enemy.global_position):
			_target_point = enemy.global_position

func _get_distance(position: Vector2) -> float:
	return (player.global_position - position).length()

func add_weapon(weapon: WeaponBase) -> void:
	for w in _weapons:
		if w == weapon:
			w.upgrade()
			return
	_weapons.append(weapon)
	add_child(weapon)
	weapon.active = true
