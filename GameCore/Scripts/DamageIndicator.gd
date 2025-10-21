class_name DamageIndicator
extends Label

@export var move_amount: float = -60.0 # O quão para cima o texto se move
@export var duration: float = 0.9 # Duração do texto na tela em segundos

func _ready() -> void:
	# Garante que o indicador apareça na frente de outros elementos
	z_index = 100

# Esta função configura o texto e inicia a animação
func show_value(amount: float) -> void:
	var rounded_amount = round(amount)
	
	# Configura o texto e a cor com base no valor
	if rounded_amount < 0:
		text = str(rounded_amount)
		modulate = Color.RED
	else:
		text = "+" + str(rounded_amount)
		modulate = Color.GREEN
	
	# Cria uma animação (Tween) para mover e desaparecer
	var tween = create_tween()
	tween.set_parallel(true)
	
	# --- ANIMAÇÃO SUAVIZADA (EASE) ---
	# 1. Anima a posição Y para cima com um "ease out"
	# (começa rápido e desacelera no final)
	tween.tween_property(self, "position:y", position.y + move_amount, duration).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	
	# 2. Anima a transparência (alpha) para criar o "fade out" com "ease in"
	# (começa a desaparecer lentamente e acelera no final)
	tween.tween_property(self, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	# --- FIM DA SUAVIZAÇÃO ---
	
	# Conecta o sinal de finalização da animação à função de se autodestruir
	tween.finished.connect(queue_free)
