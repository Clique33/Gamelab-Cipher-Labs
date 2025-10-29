extends Control
class_name MainMenu

# Para exportar uma cena (PackedScene)
@export var map_scene: PackedScene = preload("res://GameCore/Scenes/World.tscn")

var volume: float = 50

func _ready():
	var button_play = $MarginContainer/HBoxContainer/VBoxContainer/play_btn
	var button_exit = $MarginContainer/HBoxContainer/VBoxContainer/quit_btn
	
	button_exit.pressed.connect(_on_play_btn_pressed)

func _on_play_btn_pressed() -> void:
	get_tree().change_scene_to_packed(map_scene)


func _on_quit_btn_pressed() -> void:
	get_tree().quit()

func _on_option_btn_pressed() -> void:
	get_tree().current_scene.add_child(preload("res://GameCore/Scenes/Menus/OptionsMenu.tscn").instantiate())
