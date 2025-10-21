extends Control
class_name MainMenu

# Para exportar uma cena (PackedScene)
@export var map_scene: PackedScene = preload("res://GameCore/Scenes/World.tscn")

var volume: float = 50

func _ready():
	# --- Referências dos nós ---
	var vbox = $CenterContainer/Panel
	var label = $CenterContainer/Panel/Label
	var button_play = $CenterContainer/Panel/Button
	var button_exit = $CenterContainer/Panel/Button2
	var volume_slider = $CenterContainer/Panel/HSlider
	# Criar um Theme
	var theme = Theme.new()

	# Style para normal
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.1, 0.1, 0.1, 0.6)
	normal_style.corner_radius_top_left = 12
	normal_style.corner_radius_top_right = 12
	normal_style.corner_radius_bottom_left = 12
	normal_style.corner_radius_bottom_right = 12

	# Style para hover
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	hover_style.corner_radius_top_left = 12
	hover_style.corner_radius_top_right = 12
	hover_style.corner_radius_bottom_left = 12
	hover_style.corner_radius_bottom_right = 12

	# Aplicar ao Theme
	theme.set_stylebox("normal", "Button", normal_style)
	theme.set_stylebox("hover", "Button", hover_style)

	# Aplicar Theme ao VBox (que afeta todos os Buttons filhos)
	vbox.theme = theme
	button_play.pressed.connect(_on_button_pressed)
	button_exit.pressed.connect(_on_button_2_pressed)
	volume_slider.value_changed.connect(_on_volume_changed)
	# Inicializar valor do volume
	volume_slider.value = volume

	var bus = AudioServer.get_bus_index("Master")
	var db = AudioServer.get_bus_volume_db(bus)
	$CenterContainer/Panel/HSlider.value = db_to_linear(db) * 100

func _on_button_pressed() -> void:
	get_tree().change_scene_to_packed(map_scene)

func _on_button_2_pressed() -> void:
	get_tree().quit() # Replace with function body.

func _on_volume_changed(value):
	# Define o volume global do bus "Master"
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value / 100.0))
