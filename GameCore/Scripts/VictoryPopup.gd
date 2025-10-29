extends Control
class_name VictoryPopup

# VictoryPopup.gd – Godot 4 ready
# Pausa o jogo ao aparecer, mas mantém popup interativo

var title_label: Label = null
var stats_label: Label = null
var ok_button: Button = null
var ok2_button: Button = null

# Fallbacks numéricos para compatibilidade
const PAUSE_PROCESS: int = 2      # Node.pause_mode = PROCESS
const PROCESS_ALWAYS: int = 2     # Node.process_mode = ALWAYS

func _ready() -> void:
	# Localiza nós dinamicamente na cena atual
	title_label = _find_node_in_scene("Title") as Label
	stats_label = _find_node_in_scene("Stats") as Label
	ok_button = _find_node_in_scene("OK") as Button
	ok2_button = _find_node_in_scene("OK2") as Button

	# Conecta sinais dos botões
	if ok_button and not ok_button.is_connected("pressed", Callable(self, "_on_ok_pressed")):
		ok_button.pressed.connect(Callable(self, "_on_ok_pressed"))
	if ok2_button and not ok2_button.is_connected("pressed", Callable(self, "_on_ok2_pressed")):
		ok2_button.pressed.connect(Callable(self, "_on_ok2_pressed"))

	# Configura o popup para continuar processando enquanto o jogo está pausado
	self.set("pause_mode", PAUSE_PROCESS)
	_safe_set_process_mode(self, PROCESS_ALWAYS)

	# Configura botões para continuar processando e receber input enquanto pausado
	if ok_button:
		ok_button.set("pause_mode", PAUSE_PROCESS)
		_safe_set_process_mode(ok_button, PROCESS_ALWAYS)
	if ok2_button:
		ok2_button.set("pause_mode", PAUSE_PROCESS)
		_safe_set_process_mode(ok2_button, PROCESS_ALWAYS)

	# Inicialmente invisível; será mostrado via play_victory_particles()
	visible = false

# Atualiza o texto da UI
func set_stats(kills: int, time_seconds: float) -> void:
	if title_label:
		title_label.text = "VITÓRIA!"

	var t := int(time_seconds)   # primeiro converte para inteiro
	var mins := t / 60           # ou t div 60, mas usando / funciona
	var secs := t % 60

	var stats_text = "Mortes: %d\nTempo: %02d:%02d" % [kills, mins, secs]

	if stats_label:
		stats_label.text = stats_text


# Mostra o popup, pausa o jogo e emite partículas
func play_victory_particles() -> void:
	# Configura toda a subtree para processar enquanto pausado
	_set_subtree_pause_process(self)

	# Pausa a cena principal (jogo de fundo)
	get_tree().paused = true

	# Mostra popup
	visible = true

	# Ativa shader de fogos (ColorRect) se existir
	var fireworks := _find_node_in_scene("FireworksLayer")
	if fireworks and fireworks is ColorRect:
		fireworks.visible = true
		var mat : ShaderMaterial = fireworks.get("material")
		if mat and mat is ShaderMaterial:
			var sz = get_viewport_rect().size
			mat.set_shader_parameter("resolution", sz)

# --- Funções auxiliares para buscar nós ---
func _find_node_in_scene(name: String) -> Node:
	var root = get_tree().current_scene
	if root == null:
		return null
	return _find_node_recursive(root, name)

func _find_node_recursive(node: Node, name: String) -> Node:
	if node.name == name:
		return node
	for child in node.get_children():
		if child and child is Node:
			var f = _find_node_recursive(child, name)
			if f:
				return f
	return null

# --- Configura pause/process em toda a subtree ---
func _set_subtree_pause_process(node: Node) -> void:
	if node == null:
		return
	node.set("pause_mode", PAUSE_PROCESS)
	_safe_set_process_mode(node, PROCESS_ALWAYS)
	for child in node.get_children():
		if child and child is Node:
			_set_subtree_pause_process(child)

# --- Define process_mode de forma segura ---
func _safe_set_process_mode(node: Node, mode: int) -> void:
	if node == null:
		return
	for prop in node.get_property_list():
		if prop is Dictionary and prop.has("name") and str(prop["name"]) == "process_mode":
			node.set("process_mode", mode)
			return


func _on_play_btn_2_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://GameCore/Scenes/World.tscn")


func _on_quit_btn_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://GameCore/Scenes/Menus/MainMenu.tscn")


func _on_continue_btn_pressed() -> void:
	get_tree().paused = false
	queue_free()
