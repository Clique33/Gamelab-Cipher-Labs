extends CanvasLayer
@export var menu_principal : PackedScene

func _ready(): 
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		handle_pause()

func handle_pause():
	visible = !visible;
	get_tree().paused = !get_tree().paused;
	$"../AudioStreamPlayer2D".stream_paused = visible

func _on_resume_btn_pressed() -> void:
	handle_pause()

func _on_quit_btn_pressed() -> void:
	handle_pause()
	get_tree().change_scene_to_file("res://GameCore/Scenes/Menus/MainMenu.tscn")


func _on_button_pressed() -> void:
	handle_pause()
