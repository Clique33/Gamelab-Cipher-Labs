extends Control

const GRAY_HEALTH_DELAY = 0.5

@onready var current_ui: ProgressBar = $current_bar
@onready var gray_ui: ProgressBar = $gray_health

func handle_change(new_value: float):
	var diff = new_value - current_ui.value
	current_ui.value = new_value
	if diff < 0:
		# only handle gray health if there was damage
		handle_gray_health(-diff)
	elif diff > 0:
		# if health increased, update gray health immediately
		gray_ui.value = new_value


func update_gray_ui(value: float):
	# reduces the gray health bar by the damage value
	gray_ui.value -= value



func handle_gray_health(value: float) -> DamageTimer:
	# creates a one-shot timer that will emit the damage value after a delay
	var timer = DamageTimer.new(value)
	timer.wait_time = GRAY_HEALTH_DELAY
	timer.one_shot = true
	add_child(timer)
	timer.start()
	timer.timeout_value.connect(update_gray_ui)
	return timer
