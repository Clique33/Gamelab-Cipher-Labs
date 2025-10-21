extends Control
class_name DeathPopup
# --- Exporta os caminhos das cenas ---
@export var world_scene_path: String = "res://GameCore/Scenes/World.tscn"
@export var main_menu_scene_path: String = "res://GameCore/Scenes/Menus/MainMenu.tscn"
# --- Nós internos ---
var ok_button: Button
var ok2_button: Button
var title_label: Label
var stats_label: Label

func _ready() -> void:
	# Localiza os nós dinamicamente
	title_label = $CenterContainer/Panel/Title
	ok_button = $CenterContainer/Panel/OK
	ok2_button = $CenterContainer/Panel/OK2
	# Conecta sinais dos botões
	ok_button.pressed.connect(Callable(self, "_on_ok_pressed"))
	ok2_button.pressed.connect(Callable(self, "_on_ok2_pressed"))
	# Permite que o popup e botões funcionem mesmo com o jogo pausado
	_set_subtree_process_mode(self)
	visible = false

# --- Atualiza estatísticas ---
func set_stats(kills: int, time_seconds: float) -> void:
	if title_label:
		title_label.text = "DERROTA"
	var mins: int = int(time_seconds) / 60
	var secs: int = int(time_seconds) % 60
	if stats_label:
		stats_label.text = "Mortes: %d\nTempo: %02d:%02d" % [kills, mins, secs]

# --- Mostra popup e pausa o jogo ---
func play_death_effects() -> void:
	_set_subtree_process_mode(self)
	get_tree().paused = true
	visible = true
	# Emite partículas se houver
	var pnode := $CenterContainer/Panel/Particles
	if pnode and pnode is CPUParticles2D:
		pnode.emitting = true

# --- Botões ---
func _on_ok_pressed() -> void:
	get_tree().paused = false
	print("Redirecionando para: ", world_scene_path)
	if world_scene_path:
		get_tree().change_scene_to_file(world_scene_path)
	else:
		print("Erro: world_scene_path não está definido!")

func _on_ok2_pressed() -> void:
	get_tree().paused = false
	print("Redirecionando para: ", main_menu_scene_path)
	if main_menu_scene_path:
		get_tree().change_scene_to_file(main_menu_scene_path)
	else:
		print("Erro: main_menu_scene_path não está definido!")

func _set_subtree_process_mode(node: Node) -> void:
	if node == null:
		return
	node.process_mode = Node.PROCESS_MODE_ALWAYS
	for child in node.get_children():
		_set_subtree_process_mode(child)
