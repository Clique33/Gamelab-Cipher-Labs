extends Timer
class_name DamageTimer

var data_value: float
signal timeout_value(value: float)

func _init(value: float) -> void:
	data_value = value

func _ready() -> void:
	timeout.connect(_on_timeout)

func _on_timeout():
	timeout_value.emit(data_value)
	queue_free()
