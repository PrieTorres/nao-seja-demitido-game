extends BaseLevel

var escova_count = 0

@onready var Mouth: Sprite2D = $Mouth
@onready var Escova: Sprite2D = $Escova

@onready var Audio: AudioStreamPlayer = $Audio
@onready var Brush: AudioStreamPlayer = $Brush

var brush = 0
var target_score = 4

# How far to move each press
const MOVE_DISTANCE := 500  # pixels (change as you like)
# Optional: limit how far left/right it can go
const MIN_X := 445
const MAX_X := 507

func _ready() -> void:
	success_sounds = [
		preload("res://Sounds/Estevao/boa estevao.wav"),
		preload("res://Sounds/Estevao/ai sim.wav"),
	]
	
	fail_sounds = [
		preload("res://Sounds/Estevao/nao foi dessa vez.wav"),
		preload("res://Sounds/Estevao/deu ruim.mp3"),
	]
	difficulty = LevelManager.difficulty
	
	if difficulty == 1:
		Mouth.texture = load("res://All/pri1.png")
	
	if difficulty == 2:
		Mouth.texture = load("res://All/kelcia1.png")
	
	if difficulty == 3:
		Mouth.texture = load("res://All/estevao1.png")
	
	target_score = target_score + (difficulty * 4)

func _process(delta: float) -> void:
	if is_success:
		Escova.visible = false
		# Change mouth texture to good-mouth image
		
		if difficulty == 1:
			Mouth.texture = load("res://All/pri2.png")
		
		if difficulty == 2:
			Mouth.texture = load("res://All/kelcia2.png")
		
		if difficulty == 3:
			Mouth.texture = load("res://All/estevao2.png")
		return
	
	if brush > 0:
		brush -= 1
		Brush.stream_paused = false
	else:
		Brush.stream_paused = true

	if Input.is_action_just_pressed("left"):
		if escova_count % 2 == 0:
			brush = 10
			escova_count += 1
			move_escova(-MOVE_DISTANCE)

	if Input.is_action_just_pressed("right"):   
		if escova_count % 2 == 1:
			brush = 10
			escova_count += 1
			move_escova(MOVE_DISTANCE)
	
	var final_score = floor(escova_count / 2)
	if final_score > target_score:
		Audio.play()
		Brush.stream_paused = true
		_success()

func move_escova(offset_x: float) -> void:
	var target_x = clamp(Escova.position.x + offset_x, MIN_X, MAX_X)
	var tween = create_tween()
	tween.tween_property(Escova, "position:x", target_x, 0.2)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
