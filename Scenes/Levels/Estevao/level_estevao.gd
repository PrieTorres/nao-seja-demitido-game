extends BaseLevel

class_name LevelEstevao

@export var mushrooms: Array[Mushroom]
@onready var Audio: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	difficulty = LevelManager.difficulty
	success_sounds = [
		preload("res://Sounds/Estevao/boa estevao.wav"),
		preload("res://Sounds/Estevao/ai sim.wav"),
	]
	
	fail_sounds = [
		preload("res://Sounds/Estevao/nao foi dessa vez.wav"),
		preload("res://Sounds/Estevao/deu ruim.mp3"),
	]
	
	if difficulty == 1:
		mushrooms[2].queue_free()
		mushrooms[1].queue_free()
		mushrooms.pop_front()
		mushrooms.pop_front()
	
	if difficulty == 2:
		mushrooms[2].queue_free()
		mushrooms.pop_front()
