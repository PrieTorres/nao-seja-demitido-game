extends Node2D

signal level_finished(success: bool)

@export var duration: float = 15.0
@export var target_kills: int = 20
@export var spawn_interval: float = 0.6
@export var bug_speed_range: Vector2 = Vector2(90, 160)
@export var max_concurrent_bugs: int = 20
@export var initial_delay: float = 0.5
@export var allow_vertical_spawns: bool = false

@onready var _level_timer: Timer = $LevelTimer
@onready var _spawn_timer: Timer = $SpawnTimer
@onready var _time_label: Label = $CanvasLayer/HBoxContainer/TimeLabel
@onready var _score_label: Label = $CanvasLayer/HBoxContainer/ScoreLabel
@onready var _status_label: Label = $CanvasLayer/HBoxContainer/StatusLabel

@export var game_viewport_path: NodePath
@onready var _game_viewport: SubViewport = get_node(game_viewport_path) as SubViewport

var _bug_scene: PackedScene = preload("res://Pri level/scenes/Bug.tscn")
var _rng := RandomNumberGenerator.new()
var _kills: int = 0
var _running: bool = false
var _time_left: float

func _ready() -> void:
	_rng.randomize()
	_setup_timers()
	
	if _game_viewport:
		if not _game_viewport.handle_input_locally:
			_game_viewport.handle_input_locally = true
			print("[Level] handle_input_locally habilitado por código para:", _game_viewport.name)
		_game_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	# (A) conecta o sinal via código, caso o editor tenha perdido a conexão
	if not _spawn_timer.timeout.is_connected(Callable(self, "_on_SpawnTimer_timeout")):
		_spawn_timer.timeout.connect(Callable(self, "_on_SpawnTimer_timeout"))

	if not _level_timer.timeout.is_connected(Callable(self, "_on_LevelTimer_timeout")):
		_level_timer.timeout.connect(Callable(self, "_on_LevelTimer_timeout"))

	# Connect to TransitionLayer's mouse_clicked signal
	var transition_layer = get_tree().get_first_node_in_group("transition_layer")
	
	if transition_layer:
		transition_layer.mouse_clicked.connect(_on_transition_click)
		print("[Level] Connected to TransitionLayer mouse_clicked signal")
	else:
		print("[Level] Warning: TransitionLayer not found!")

	# (B) prints de sanidade
	print("GV size=", _game_viewport and _game_viewport.size)
	print("SpawnTimer wait_time=", _spawn_timer.wait_time, " one_shot=", _spawn_timer.one_shot, " running=", not _spawn_timer.is_stopped())

	_reset_ui()
	start_level()

#func find_child_by_class(class_name: String) -> Node:
	#return find_child_by_class_recursive(get_tree().root, class_name)

#func find_child_by_class_recursive(node: Node, class_name: String) -> Node:
	#if node.get_class() == class_name:
		#return node
	#
	#for child in node.get_children():
		#var result = find_child_by_class_recursive(child, class_name)
		#if result:
			#return result
	#
	#return null

func _on_transition_click(click_pos: Vector2) -> void:
	print("[Level] Click received at: ", click_pos)
	var canvas_transform: Transform2D = _game_viewport.get_canvas_transform()
	var inv_transform: Transform2D = canvas_transform.affine_inverse()
	var local_click_pos: Vector2 = inv_transform * click_pos  # usar operador * em vez de xform()
	
	# Check if the click position matches any bug
	var params := PhysicsPointQueryParameters2D.new()
	params.position = local_click_pos
	params.collide_with_areas = true
	params.collision_mask = 0x7FFFFFFF
	
	var space = _game_viewport.get_world_2d().direct_space_state
	var hits: Array[Dictionary] = space.intersect_point(params, 32)
	
	for d in hits:
		var bug_area: Area2D = d.get("collider") as Area2D
		if bug_area and bug_area.is_in_group("bugs"):
			print("[Level] Bug hit! Killing bug")
			bug_area.emit_signal("killed")
			bug_area.queue_free()
			_on_bug_killed()
			break

func _setup_timers() -> void:
	_level_timer.one_shot = true
	_spawn_timer.one_shot = false

func _reset_ui() -> void:
	_kills = 0
	_time_left = duration
	_update_ui()
	_status_label.text = ""
	_status_label.visible = false

func start_level() -> void:
	_running = true
	_reset_ui()
	_level_timer.wait_time = duration
	_level_timer.start()
	_spawn_timer.wait_time = spawn_interval
	get_tree().create_timer(initial_delay).timeout.connect(func():
		if _running:
			_spawn_timer.start()
	)

func stop_level() -> void:
	_running = false
	_level_timer.stop()
	_spawn_timer.stop()

func _process(_delta: float) -> void:
	if _running:
		_time_left = max(0.0, _level_timer.time_left)
		_update_ui()

func _update_ui() -> void:
	_time_label.text = "Tempo: %.1f" % _time_left
	_score_label.text = "Kills: %d/%d" % [_kills, target_kills]

func _on_bug_killed() -> void:
	_kills += 1
	_update_ui()
	if _kills >= target_kills:
		_end_level(true)

func _end_level(success: bool) -> void:
	if not _running:
		return
	stop_level()
	_status_label.visible = true
	_status_label.text = "✅ Sucesso!" if success else "❌ Falha!"
	emit_signal("level_finished", success)
	for b in get_tree().get_nodes_in_group("bugs"):
		if is_instance_valid(b):
			b.queue_free()

func _on_SpawnTimer_timeout() -> void:
	if not _running:
		return
	if get_tree().get_nodes_in_group("bugs").size() >= max_concurrent_bugs:
		return
	var bug := _bug_scene.instantiate()
	bug.add_to_group("bugs")  
	bug.connect("killed", Callable(self, "_on_bug_killed"))  # conectar sinal  
	_game_viewport.add_child(bug)  # adicionar o bug na subviewport
	
	var bug_click_callable := Callable(self, "_on_bug_input_event").bind(bug)
	if not bug.is_connected("input_event", bug_click_callable):
			bug.connect("input_event", bug_click_callable)
	
	var bounds := _get_play_bounds()
	var start_pos: Vector2
	var end_pos: Vector2
	var edge := _rng.randi_range(0, 3 if allow_vertical_spawns else 1)
	var pad := 24.0  # acolchoamento interno para não nascer colado na borda
	var outer := 32.0  # margem fora da área visível

	match edge:
		0: # nasce à ESQUERDA (fora) -> atravessa pra DIREITA (fora)
			start_pos = Vector2(bounds.position.x - outer, _rng.randf_range(bounds.position.y, bounds.end.y))
			end_pos   = Vector2(bounds.end.x + outer,      start_pos.y + _rng.randf_range(-80, 80))

		1: # nasce à DIREITA (fora) -> atravessa pra ESQUERDA (fora)
			start_pos = Vector2(bounds.end.x + outer,      _rng.randf_range(bounds.position.y, bounds.end.y))
			end_pos   = Vector2(bounds.position.x - outer, start_pos.y + _rng.randf_range(-80, 80))

		2: # nasce em CIMA (fora) -> atravessa pra BAIXO (fora)  [se allow_vertical_spawns = true]
			start_pos = Vector2(_rng.randf_range(bounds.position.x, bounds.end.x), bounds.position.y - outer)
			end_pos   = Vector2(start_pos.x + _rng.randf_range(-80, 80),            bounds.end.y + outer)

		3: # nasce em BAIXO (fora) -> atravessa pra CIMA (fora)
			start_pos = Vector2(_rng.randf_range(bounds.position.x, bounds.end.x), bounds.end.y + outer)
			end_pos   = Vector2(start_pos.x + _rng.randf_range(-80, 80),            bounds.position.y - outer)

	bug.call("setup", start_pos, end_pos, bug_speed_range, bounds)
	bug.connect("killed", Callable(self, "_on_bug_killed"))

func _get_play_bounds() -> Rect2:
	if _game_viewport:
		var sz := _game_viewport.size
		return Rect2(Vector2.ZERO, Vector2(sz.x, sz.y))
	return Rect2(Vector2.ZERO, get_viewport_rect().size)

func _on_LevelTimer_timeout() -> void:
	_end_level(_kills >= target_kills)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		print("[Level] _input no GameRoot. Viewport=", get_viewport().name, " btn=", event.button_index)

func _on_bug_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int, bug: Area2D) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				print("[Level] click recebido do bug id=", bug.get_instance_id())
				bug.call("kill")
				

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos: Vector2 = get_viewport().get_mouse_position()

		var params := PhysicsPointQueryParameters2D.new()
		params.position = mouse_pos
		params.collide_with_areas = true
		params.collide_with_bodies = false
		params.collision_mask = 0x7FFFFFFF  # ajuste se usar layers

		var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
		var hits: Array[Dictionary] = space.intersect_point(params, 32)  # Godot 4: (params, max_results)

		for d in hits:
			var bug_area: Area2D = d.get("collider") as Area2D
			if bug_area and bug_area.is_in_group("bugs"):
				bug_area.emit_signal("killed")
				bug_area.queue_free()
				_on_bug_killed()
				break
