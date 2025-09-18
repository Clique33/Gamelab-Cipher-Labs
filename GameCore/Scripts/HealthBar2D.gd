extends Node2D

@export var width: float = 24.0
@export var height: float = 4.0
@export var y_offset: float = 25.0
@export var bg_color: Color = Color(0, 0, 0, 0.6)
@export var fg_color: Color = Color(0.2, 0.9, 0.2, 0.95)
@export var border_color: Color = Color(1, 1, 1, 0.15)
@export var border_thickness: float = 1.0

var _max_health: float = 1.0
var _current_health: float = 1.0

@onready var health_node: Node = get_parent().get_node("Health") if get_parent().has_node("Health") else null

func _ready() -> void:
	z_index = 10
	position = Vector2(0, y_offset)
	set_process(true)
	if health_node and health_node.get("status") != null:
		var st = health_node.get("status")
		if st:
			_connect_status(st)
	queue_redraw()

func _process(_delta: float) -> void:
	# Garante o offset abaixo do player mesmo se escalas mudarem
	position = Vector2(0, y_offset)

func _connect_status(st) -> void:
	_max_health = st.MaxHealth
	_current_health = st.CurrentHealth
	if not st.health_changed.is_connected(_on_health_changed):
		st.health_changed.connect(_on_health_changed)
	if not st.max_health_changed.is_connected(_on_max_changed):
		st.max_health_changed.connect(_on_max_changed)
	if not st.died.is_connected(_on_died):
		st.died.connect(_on_died)
	queue_redraw()

func _on_health_changed(new_value: float) -> void:
	_current_health = clamp(new_value, 0.0, _max_health)
	queue_redraw()

func _on_max_changed(new_max: float) -> void:
	_max_health = max(new_max, 1.0)
	_current_health = clamp(_current_health, 0.0, _max_health)
	queue_redraw()

func _on_died() -> void:
	hide()

func _draw() -> void:
	if _max_health <= 0.0:
		return
	var w = width
	var h = height
	var origin = Vector2(-w * 0.5, 0)
	# Fundo
	draw_rect(Rect2(origin, Vector2(w, h)), bg_color, true)
	# Borda
	if border_thickness > 0.0:
		draw_rect(Rect2(origin, Vector2(w, h)), border_color, false, border_thickness)
	# Barra
	var ratio = clamp(_current_health / _max_health, 0.0, 1.0)
	var fw = w * ratio
	draw_rect(Rect2(origin, Vector2(fw, h)), fg_color, true)
