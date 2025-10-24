extends Node2D

func _process(delta: float) -> void:
	await get_tree().create_timer(18.0).timeout
	get_tree().change_scene_to_file("res://Scenes/LevelManager.tscn")
