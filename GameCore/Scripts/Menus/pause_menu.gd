extends CanvasLayer
@export var menu_principal : PackedScene

func _on_resume_btn_pressed() -> void:
	pass # Replace with function body.

func _on_quit_btn_pressed() -> void:
	get_tree().change_scene_to_packed(menu_principal)
