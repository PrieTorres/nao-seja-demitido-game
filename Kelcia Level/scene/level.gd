extends BaseLevel

class_name LevelKelcia

@export var cafe1: AnimatedSprite2D
@export var cafe2: AnimatedSprite2D
@export var cafe3: AnimatedSprite2D

@onready var Audio: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	difficulty = LevelManager.difficulty
	success_sounds = [
		preload("res://All/kelciagood1.wav"),
		preload("res://All/kelciagood2.wav"),
	]
	
	fail_sounds = [
		preload("res://All/kelciabad1.wav"),
		preload("res://All/kelciabad2.wav"),
	]
	
	if difficulty == 1:
		cafe2.queue_free()
		cafe3.queue_free()
	if difficulty == 2:
		cafe1.queue_free()
		cafe3.queue_free()
	if difficulty == 3:
		cafe2.queue_free()
		cafe1.queue_free()
