extends Area2D

signal killed

@export var speed: float = 90.0
var _bounds: Rect2 = Rect2(128, 96, 800, 600)
var _dir: Vector2 = Vector2.RIGHT.rotated(randf() * TAU)
var _dead: bool = false

func set_bounds(rect: Rect2) -> void:
	_bounds = rect

func _ready() -> void:
	input_pickable = true  # garante _input_event em Area2D
	add_to_group("bugs")

func _physics_process(delta: float) -> void:
	if _dead:
		return
	# movimentação simples dentro do retângulo da “tela do PC”
	position += _dir * speed * delta
	# bate e volta nas bordas
	if position.x < _bounds.position.x or position.x > _bounds.position.x + _bounds.size.x:
		_dir.x *= -1
		position.x = clamp(position.x, _bounds.position.x, _bounds.position.x + _bounds.size.x)
	if position.y < _bounds.position.y or position.y > _bounds.position.y + _bounds.size.y:
		_dir.y *= -1
		position.y = clamp(position.y, _bounds.position.y, _bounds.position.y + _bounds.size.y)

func _input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		kill()

func kill() -> void:
	if _dead:
		return
	_dead = true
	emit_signal("killed")
	queue_free()
