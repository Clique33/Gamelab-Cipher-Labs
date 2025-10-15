extends Node

const UPGRADE_SCENE_DIR: String = "res:"

var container: Node # to hold not applied upgrades
var upgrades: Array[Upgrade]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _load_upgrades() -> void:
	var dir := DirAccess.open(UPGRADE_SCENE_DIR)
	if not dir:
		print("Error loading upgrades")
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		var scene := load(UPGRADE_SCENE_DIR.path_join(file_name)) as PackedScene
		var instance = scene.instantiate()
		assert(instance is Upgrade, "file is not upgrade")
		container.call_deferred("add_child", instance)
		upgrades.append(instance)
		file_name = dir.get_next()
	dir.list_dir_end()
