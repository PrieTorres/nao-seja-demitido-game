extends BaseLevel

signal level_finished(success: bool)

@export var target_kills: int = 10
@export var level_duration_sec: int = 15
@export var spawn_interval_sec: float = 0.8
@export var max_bugs_alive: int = 50
@export var bug_scene: PackedScene
@export var screen_rect: Rect2 = Rect2(128, 96, 540, 300)  # área da “tela do PC” no Background

@onready var _spawn_timer: Timer = $SpawnTimer
@onready var _level_timer: Timer = $LevelTimer
@onready var _score_label: Label = $UI/Box/ScoreLabel
@onready var _time_label: Label = $UI/Box/TimeLabel
#@onready var _goal_label: Label = $UI/Box/GoalLabel
@onready var _result_label: Label = $UI/Box/StatusLabel
@onready var _bug_spawn_area: Node2D = $BugSpawnArea

var _kills: int = 0
var _alive: int = 0
var _time_left: int

func _ready() -> void:
	if(_result_label):
		_result_label.visible = false
	_kills = 0
	_alive = 0
	_time_left = level_duration_sec
	_update_ui()

	# Timers
	_spawn_timer.wait_time = spawn_interval_sec
	_spawn_timer.one_shot = false
	_spawn_timer.timeout.connect(_on_SpawnTimer_timeout)
	_spawn_timer.start()

	_level_timer.wait_time = 1.0
	_level_timer.one_shot = false
	_level_timer.timeout.connect(_on_LevelTimer_tick)
	_level_timer.start()

	# (Opcional) Capturar clique emitido pelo seu TransitionLayer/autoload
	# Se você usa o TransitionLayer para clique global, conecte aqui:
	var tl = get_tree().get_first_node_in_group("transition_layer")
	if tl and tl.has_signal("mouse_clicked"):
		tl.mouse_clicked.connect(_on_transition_click)
		print("[Level] Connected to TransitionLayer mouse_clicked signal")

func _on_LevelTimer_tick() -> void:
	_time_left -= 1
	_update_ui()
	if _time_left <= 0:
		_end_level(_kills >= target_kills)

func _on_SpawnTimer_timeout() -> void:
	if _alive >= max_bugs_alive:
		return
	_spawn_bug()

func _spawn_bug() -> void:
	if bug_scene == null:
		push_warning("bug_scene não definido no Level")
		return

	var bug = bug_scene.instantiate()
	bug.add_to_group("bugs")
	# posição aleatória dentro da área da “tela do PC”
	bug.position = Vector2(
		randf_range(screen_rect.position.x, screen_rect.position.x + screen_rect.size.x),
		randf_range(screen_rect.position.y, screen_rect.position.y + screen_rect.size.y)
	)

	# Passar limites para o bug (para ele não sair da tela do PC)
	if bug.has_method("set_bounds"):
		bug.call("set_bounds", screen_rect)

	# Conectar sinal de kill -> contabilizar
	if bug.has_signal("killed"):
		bug.killed.connect(_on_bug_killed)

	add_child(bug)
	_alive += 1

func _on_bug_killed() -> void:
	_kills += 1
	_alive = max(_alive - 1, 0)
	_update_ui()
	if _kills >= target_kills:
		_end_level(true)

func _end_level(success: bool) -> void:
	_spawn_timer.stop()
	_level_timer.stop()
	_result_label.visible = true
	_result_label.text = "✅ SUCESSO!" if success else "❌ FRACASSO"
	emit_signal("level_finished", success)

func _update_ui() -> void:
	_score_label.text = "Kills: %d" % _kills
	#_goal_label.text = "Meta: %d" % target_kills
	_time_label.text = "Tempo: %ds" % _time_left

# 2 caminhos para clicar e matar:
# A) Se usa TransitionLayer.emit_signal("mouse_clicked", pos) -> pega aqui:
func _on_transition_click(click_pos: Vector2) -> void:
	_try_kill_at(click_pos)

# B) (Opcional) Se quiser sem TransitionLayer, ative isso e clique cai aqui:
# func _unhandled_input(event: InputEvent) -> void:
#     if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
#         _try_kill_at((event as InputEventMouseButton).position)

func _try_kill_at(screen_pos: Vector2) -> void:
	# Como não há SubViewport, screen_pos já está no mesmo canvas do Level.
	var params := PhysicsPointQueryParameters2D.new()
	params.position = screen_pos
	params.collide_with_areas = true

	var space := get_world_2d().direct_space_state
	var hits = space.intersect_point(params, 32)

	for d in hits:
		var area := d.collider as Area2D
		if area and area.is_in_group("bugs"):
			# Chamar a API de kill do próprio bug (que emite 'killed' e se remove)
			if area.has_method("kill"):
				area.call("kill")
			else:
				# fallback, se o bug não tiver 'kill'
				if area.has_signal("killed"):
					area.emit_signal("killed")
				area.queue_free()
			break
