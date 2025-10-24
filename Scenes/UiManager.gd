extends Control

class_name UiManager

@export var LevelManager: LevelManager
@onready var LevelTimerText = %LevelTimerText

func _process(delta: float) -> void:
	if LevelManager.LevelTimer.is_stopped():
		LevelTimerText.text = "0.00"
	else:
		LevelTimerText.text = str(LevelManager.LevelTimer.time_left).pad_decimals(2)
