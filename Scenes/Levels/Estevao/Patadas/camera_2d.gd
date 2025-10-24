# Camera2D.gd (Godot 4.x)
extends Camera2D

const BASE_RES := Vector2(800, 600)

func _ready() -> void:
	enabled = true
	_update_zoom()
	# React whenever the game window / viewport size changes
	get_viewport().size_changed.connect(_update_zoom)

func _update_zoom() -> void:
	var win_size: Vector2 = get_viewport().get_visible_rect().size
	# Zoom so that world units always match your base resolution
	# (If the window is 1600x1200, zoom becomes 0.5,0.5 = clean 2× scale)
	zoom = BASE_RES / win_size
