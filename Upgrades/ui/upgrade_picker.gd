extends VBoxContainer

var available: Array[Upgrade] = []
var row_scene: PackedScene
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	available = _select_random(3)
	for i in range(available.size()):
		var instance = row_scene.instantiate()
		assert(instance is UpgradeRow)
		instance.upgrade = available[i]
		add_child(instance)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _select_random(amount: int) -> Array[Upgrade]:
	var total := UpgradesManager.upgrades.duplicate()
	var ans: Array[Upgrade] = []
	for i in range(amount):
		var index = randi() % total.size()
		ans.append(total.pop_at(index))
	return ans
