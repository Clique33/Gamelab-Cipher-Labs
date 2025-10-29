extends Control
class_name MainMenu

# Para exportar uma cena (PackedScene)
@export var map_scene: PackedScene = preload("res://GameCore/Scenes/World.tscn")

var volume: float = 50

func _ready():
	var button_play = $MarginContainer/HBoxContainer/VBoxContainer/play_btn
	var button_exit = $MarginContainer/HBoxContainer/VBoxContainer/quit_btn
	var volume_slider = $MarginContainer/HBoxContainer/VBoxContainer/HSlider
	
	button_play.pressed.connect(_on_volume_changed)
	button_exit.pressed.connect(_on_play_btn_pressed)
	volume_slider.value_changed.connect(_on_volume_changed)
	# Inicializar valor do volume
	volume_slider.value = volume

	var bus = AudioServer.get_bus_index("Master")
	var db = AudioServer.get_bus_volume_db(bus)
	volume_slider.value = db_to_linear(db) * 100

func _on_volume_changed(value):
	# Define o volume global do bus "Master"
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value / 100.0))

func _on_play_btn_pressed() -> void:
	get_tree().change_scene_to_packed(map_scene)


func _on_quit_btn_pressed() -> void:
	get_tree().quit()
