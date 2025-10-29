extends Control
class_name OptionsMenu

var volume: float = 20


func _ready():
	var volume_slider := $VBoxContainer/HSlider
	volume_slider.value = volume

	var bus = AudioServer.get_bus_index("Master")
	var db = AudioServer.get_bus_volume_db(bus)
	volume_slider.value = db_to_linear(db) * 100

func _on_quit_btn_pressed() -> void:
	get_tree().quit()


func _on_h_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value / 100.0))

func _on_return_btn_pressed() -> void:
	queue_free()

func _on_fullscreen_check_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
