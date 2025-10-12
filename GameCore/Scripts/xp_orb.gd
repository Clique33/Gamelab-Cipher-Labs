extends Area2D
class_name XPOrb

## Orb de experiência que é dropado pelos inimigos
## Atrai-se ao jogador quando próximo e dá XP ao ser coletado

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

## Quantidade de XP que este orb dá ao ser coletado
@export var xp_value: int = 1

## Velocidade de movimento do orb em direção ao player
@export var move_speed: float = 200.0

## Distância a partir da qual o orb começa a ser atraído pelo player
@export var attraction_range: float = 100.0

## Referência ao player (detectado automaticamente)
var player: Player = null

## Se o orb está sendo atraído pelo player
var is_attracted: bool = false

signal collected(xp_amount: int)

func _ready() -> void:
	add_to_group("xp_orb")
	# Conecta o sinal de body_entered para detectar coleta
	body_entered.connect(_on_body_entered)
	# Busca o player na cena
	_find_player()
	animated_sprite.play("idle")
	
func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		_find_player()
		return
	
	# Calcula distância até o player
	var distance_to_player: float = global_position.distance_to(player.global_position)
	
	# Se estiver dentro do range de atração, move em direção ao player
	if distance_to_player <= attraction_range:
		is_attracted = true
		var direction: Vector2 = (player.global_position - global_position).normalized()
		global_position += direction * move_speed * delta

func _find_player() -> void:
	var players: Array = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _on_body_entered(body: Node2D) -> void:
	# Se o player tocou o orb, coleta
	if body.is_in_group("player"):
		_collect(body)

func _collect(collector: Node2D) -> void:
	# Adiciona XP ao player
	if collector is Player:
		collector.add_experience(xp_value)
	
	# Emite signal com a quantidade de XP
	collected.emit(xp_value)
	
	# Remove o orb da cena
	queue_free()
