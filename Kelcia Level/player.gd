extends CharacterBody2D

# === CONSTANTES DE MOVIMENTO ===
const SPEED = 100.0
const JUMP_VELOCITY = -300.0
const GROUND_ACCEL = 1200.0
const AIR_ACCEL = 600.0

@export var Level: LevelKelcia

# === CONSTANTES DE MORTE ===
@export var DEATH_Y: float = 600.0
@export var RESPAWN_POS: Vector2 = Vector2.ZERO

# === POSIÇÃO DE VITÓRIA ===
@export var WIN_POSITION_X: float = -9.854 
@export var WIN_POSITION_Y: float = -147.499

# === REFERÊNCIAS ===
@onready var animated_player: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $"../AnimatedSprite2D2/Area2D/CollisionShape2D"
@onready var jump: AudioStreamPlayer2D = $jump


func _ready():
	RESPAWN_POS = global_position


func _physics_process(delta: float) -> void:
	var on_floor := is_on_floor()

	# Gravidade
	if not on_floor:
		velocity += get_gravity() * delta

	# Pulo
	if Input.is_action_just_pressed("up") and on_floor:
		velocity.y = JUMP_VELOCITY
		jump.play()  # 🎵 toca o som do pulo




	# Movimento horizontal
	var direction := Input.get_axis("left", "right")
	var target_speed = direction * SPEED
	var accel = GROUND_ACCEL if on_floor else AIR_ACCEL
	velocity.x = move_toward(velocity.x, target_speed, accel * delta)

	# Animações + flip
	if on_floor:
		if abs(velocity.x) > 1.0:
			animated_player.flip_h = velocity.x < 0.0
			animated_player.play("walking")
		else:
			animated_player.play("idle")
	else:
		if abs(velocity.x) > 0.1:
			animated_player.flip_h = velocity.x < 0.0
		animated_player.play("jump")

	move_and_slide()

	# Morte e vitória
	_check_fall_death()


func _check_fall_death() -> void:
	if global_position.y > DEATH_Y:
		_die()


func _die() -> void:
	Level._fail()
	Level.is_finished = true


# === VITÓRIA POR POSIÇÃO ===


func _on_area_2d_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	if body == self:
		Level.Audio.play()
		Level._success()
		Level.is_finished = true
	pass # Replace with function body.
