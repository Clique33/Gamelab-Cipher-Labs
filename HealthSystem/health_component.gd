extends Node2D
class_name HealthComponent

signal died()

const GRAY_HEALTH_DELAY = 0.5

@export var initial_status: HealthStatus
var status: HealthStatus
@onready var current_ui: ProgressBar = $UI/current_bar
@onready var gray_ui: ProgressBar = $UI/gray_health
@onready var ui: Control = $UI

# --- NOVO: Arraste a cena DamageIndicator.tscn aqui no Inspector ---
@export var damage_indicator_scene: PackedScene

# --- NOVO: Ajuste vertical para o indicador aparecer "acima da cabeça" ---
@export var indicator_vertical_offset: float = -50.0


func damage(value: float) -> void:
	if not status: return
	status.damage(value)
	# Spawna o indicador de dano
	_spawn_indicator(-value)


func heal(value: float) -> void:
	# Heal via HealthStatus to keep signals consistent
	if not status:
		return
	
	var old_health = status.CurrentHealth
	var new_h: float = float(status.CurrentHealth) + float(value)
	status.CurrentHealth = min(new_h, float(status.MaxHealth))
	
	# Calcula o valor real da cura e spawna o indicador
	var healed_amount = status.CurrentHealth - old_health
	if healed_amount > 0:
		_spawn_indicator(healed_amount)


# API esperada: take_damage/current_health

func _ready() -> void:
	# initializes the health UI with the current health status
	status = initial_status.duplicate()
	current_ui.max_value = status.MaxHealth
	current_ui.value = status.CurrentHealth
	gray_ui.max_value = status.MaxHealth
	gray_ui.value = status.CurrentHealth
	status.health_changed.connect(ui.handle_change)
	status.died.connect(_on_died)

func _on_died():
	died.emit()

# --- FUNÇÃO ATUALIZADA ---
# Esta função é responsável por criar e posicionar o texto flutuante
func _spawn_indicator(value: float) -> void:
	if not damage_indicator_scene:
		print("HealthComponent: A cena do Indicador de Dano não foi definida!")
		return
		
	var indicator = damage_indicator_scene.instantiate()
	# Garante que a cena instanciada tem o script DamageIndicator
	if not indicator is DamageIndicator: 
		print("HealthComponent: A cena instanciada não é um DamageIndicator!")
		indicator.queue_free()
		return
		
	# Adiciona o indicador à cena principal para que não se mova com o personagem
	get_tree().current_scene.add_child(indicator)
	
	# Posiciona o indicador no topo do dono deste componente (Player ou Inimigo)
	var owner_node = get_parent()
	if owner_node is Node2D:
		# --- LÓGICA DE POSICIONAMENTO CORRIGIDA ---
		# Começa na posição do dono
		var start_position = owner_node.global_position
		# Aplica o desvio vertical para ficar acima da cabeça
		start_position.y += indicator_vertical_offset
		# Adiciona um desvio horizontal MENOR para manter centralizado
		start_position.x += randf_range(-8.0, 8.0)
		
		indicator.global_position = start_position
		# --- FIM DA CORREÇÃO ---
		
	# Inicia a animação do indicador
	indicator.show_value(value)
