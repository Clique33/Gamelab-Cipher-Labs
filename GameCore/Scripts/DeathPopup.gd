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
	$anim.play("appear")

func _set_subtree_process_mode(node: Node) -> void:
	if node == null:
		return
	node.process_mode = Node.PROCESS_MODE_ALWAYS
	for child in node.get_children():
		_set_subtree_process_mode(child)


func _on_play_btn_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(world_scene_path)


func _on_quit_btn_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(main_menu_scene_path)
