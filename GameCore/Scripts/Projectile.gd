class_name Projectile
extends Area2D

@export var speed: float = 560.0
@export var lifetime: float = 2.0
@export var damage: float = 10.0
var _dir: Vector2 = Vector2.RIGHT
# --- NOVAS VARIÁVEIS EXPORTADAS PARA O SOM ---
# 1. Permite arrastar o arquivo de som (AudioStream) no Inspetor
@export var shoot_sound: AudioStream # Tipo AudioStream para sons (wav, ogg, etc.)
# 2. Referência ao nó AudioStreamPlayer
# NOVO: Variável exportada (mantemos o export para customização)
# Removemos o @onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var sfx = $AudioStreamPlayer2D

func _ready() -> void:
	set_process(true)
	# Auto-destruir após lifetime
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
	var sfx_instance = AudioStreamPlayer2D.new()
	sfx_instance.stream = $AudioStreamPlayer2D.stream
	sfx_instance.global_position = global_position
	get_tree().root.add_child(sfx_instance)
	sfx_instance.play()

	# timer para limpar o som depois que terminar
	var t = Timer.new()
	t.one_shot = true
	t.wait_time = sfx_instance.stream.get_length()
	get_tree().root.add_child(t)
	t.start()
	t.timeout.connect(func(): sfx_instance.queue_free())

func set_direction(d: Vector2) -> void:
	if d.length() > 0.01:
		_dir = d.normalized()
	rotation = _dir.angle()

func _process(delta: float) -> void:
	global_position += _dir * speed * delta

func _on_body_entered(body: Node) -> void:
	# Aplica dano se o corpo for inimigo e tiver Health
	if body.is_in_group("enemy"):
		for child in body.get_children():
			if child is HealthComponent:
				child.damage(damage)
	queue_free()
