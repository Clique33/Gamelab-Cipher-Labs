extends Control
class_name MainMenu

# Para exportar uma cena (PackedScene)
@export var map_scene: PackedScene = preload("res://GameCore/Scenes/World.tscn")

func _on_button_pressed() -> void:
	get_tree().change_scene_to_packed(map_scene)


func _on_button_2_pressed() -> void:
	get_tree().quit() # Replace with function body.
