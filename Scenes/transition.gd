# TransitionLayer.gd (Godot 4.x)
extends CanvasLayer

const BASE_RES := Vector2i(800, 600)  # your internal resolution

@onready var root: Control = $Root
@onready var incoming_container: SubViewportContainer = $Root/IncomingContainer
@onready var incoming_viewport: SubViewport = $Root/IncomingContainer/IncomingViewport
@onready var frame_panel: Panel = $Root/Frame
@onready var scrim: ColorRect = $Root/Scrim

var current_level_instance: Node

# Signal to emit when mouse is clicked
signal mouse_clicked(position: Vector2)

@onready var Audio: AudioStreamPlayer = $AudioStreamPlayer

var swishs = [
	preload("res://Sounds/Swish/swish-1.wav"),
	preload("res://Sounds/Swish/swish-2.wav"),
	preload("res://Sounds/Swish/swish-3.wav"),
	preload("res://Sounds/Swish/swish-4.wav"),
	preload("res://Sounds/Swish/swish-5.wav"),
	preload("res://Sounds/Swish/swish-6.wav"),
	preload("res://Sounds/Swish/swish-7.wav"),
	preload("res://Sounds/Swish/swish-8.wav"),
	preload("res://Sounds/Swish/swish-9.wav"),
]

func _ready() -> void:
	# IMPORTANT: this layer should live in viewport space, not window space
	# Keep SubViewport at internal size; let the engine scale the final frame.
	incoming_container.stretch = false         # avoid a second scaling path
	# If you ever want the SubViewportContainer to stretch, then set:
	# incoming_container.stretch = true; incoming_container.stretch_shrink = 1
	# (but don't use 2 — that would double-scale on top of the global 2×)

	# Track viewport changes (fullscreen toggle, resolution switch, etc.)
	get_viewport().size_changed.connect(_on_viewport_resized)

	visible = false
	_resync_sizes()
	_reset_visuals()

func _on_viewport_resized() -> void:
	_resync_sizes()
	_reset_visuals()  # keep layout consistent after a size change

func _resync_sizes() -> void:
	# Always work in *viewport units* (internal pixels)
	var vp_size: Vector2i = get_viewport().get_visible_rect().size
	# In Viewport+Integer stretch, vp_size == BASE_RES (800×600).
	# If you ever switch to Expand, vp_size may change—this still handles it.
	root.size = vp_size
	incoming_viewport.size = vp_size

func _reset_visuals() -> void:
	root.size = get_viewport().get_visible_rect().size
	incoming_container.position = Vector2.ZERO
	incoming_container.modulate.a = 1.0

	# Frame starts expanded outside viewport (in viewport units)
	frame_panel.scale = Vector2(2.0, 2.0)
	frame_panel.modulate.a = 1.0
	if is_instance_valid(scrim):
		scrim.modulate.a = 0.0

func _clear_incoming_viewport() -> void:
	for c in incoming_viewport.get_children():
		c.queue_free()

## PUBLIC API ##
## Call: await TransitionLayer.transition_to(packed_scene, level_manager)
func transition_to(next_scene_packed: PackedScene, level_manager: LevelManager):
	visible = true
	_resync_sizes()
	_clear_incoming_viewport()

	# Instance the next scene INSIDE the SubViewport (rendered as a texture)
	var next_scene_instance: Node = next_scene_packed.instantiate()
	next_scene_instance.LevelManager = level_manager
	incoming_viewport.add_child(next_scene_instance)
	
	# Enable input forwarding through the SubViewportContainer
	incoming_container.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Connect input events to forward them to the level
	print("Connecting gui_input signal to level: ", next_scene_instance.name)
	incoming_container.gui_input.connect(_forward_input.bind(next_scene_instance))
	print("Signal connected successfully")
	
	var screen: Vector2 = root.size
	incoming_container.position = Vector2(screen.x, 0)

	# Reset visuals
	incoming_container.modulate.a = 1.0
	frame_panel.scale = Vector2(2.0, 2.0)
	frame_panel.modulate.a = 1.0
	if is_instance_valid(scrim):
		scrim.modulate.a = 0.0

	# Phase 1: frame zooms in + scene slides in (viewport units)
	var t1 = create_tween().set_parallel(true)
	t1.tween_property(frame_panel, "scale", Vector2.ONE, 0.70)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t1.tween_property(incoming_container, "position", Vector2.ZERO, 1.4)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if is_instance_valid(scrim):
		t1.tween_property(scrim, "modulate:a", 0.05, 0.40)
	
	Audio.stream = swishs[randi() % swishs.size()]
	Audio.play()
	await t1.finished

	return next_scene_instance

func _forward_input(event: InputEvent, level_instance: Node) -> void:
	# Forward input events to the level instance
	if level_instance and is_instance_valid(level_instance):
		print("Forwarding input to level: ", level_instance.name)
		
		# Try to find any SubViewport in the level
		var subviewport = _find_subviewport(level_instance)
		if subviewport:
			print("Found SubViewport: ", subviewport.name)
			# Forward input to the level's SubViewport
			subviewport.push_input(event)
		else:
			print("No SubViewport found, forwarding directly")
			# Forward input directly to the level
			level_instance._input(event)
			level_instance._unhandled_input(event)
	
	return

func _find_subviewport(node: Node) -> SubViewport:
	# Recursively search for SubViewport nodes
	if node is SubViewport:
		return node
	
	for child in node.get_children():
		var result = _find_subviewport(child)
		if result:
			return result
	
	return null

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		print("[TransitionLayer] Mouse click detected at: ", event.position)
		# Emit signal with click position
		mouse_clicked.emit(event.position)

## PUBLIC API ##
## Call: await TransitionLayer.transition_out()
func transition_out():
	visible = true
	_resync_sizes()

	frame_panel.scale = Vector2.ONE
	frame_panel.modulate.a = 1.0
	if is_instance_valid(scrim):
		scrim.modulate.a = 0.0

	var screen: Vector2 = root.size

	var t1 = create_tween().set_parallel(true)
	t1.tween_property(frame_panel, "scale", Vector2(2.0, 2.0), 0.80)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t1.tween_property(incoming_container, "position", Vector2(-screen.x, 0), 0.70)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	if is_instance_valid(scrim):
		t1.tween_property(scrim, "modulate:a", 0.05, 0.40)
	await t1.finished

	_clear_incoming_viewport()
	_reset_visuals()
	visible = false
	return
