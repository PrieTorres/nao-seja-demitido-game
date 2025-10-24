extends Node

class_name LevelManager

@export var LevelTimer: Timer
@export var TransitionTimer: Timer

@onready var is_on_level = false
@onready var current_level: PackedScene
@onready var current_level_instance: BaseLevel
@onready var current_level_index = -1
@onready var lives = 3
@onready var difficulty = 1

@onready var MainAudio: AudioStreamPlayer = $MainAudio
@onready var Audio: AudioStreamPlayer = $AudioStreamPlayer

var transition_going = false

@onready var level_list: Array[PackedScene] = [
	preload("res://Scenes/Levels/Estevao/Escova/EscovaLevel.tscn"),
	preload("res://Pri level/Level.tscn"),
	preload("res://Scenes/Levels/Estevao/Patadas/Patadas.tscn"),
	preload("res://Scenes/Levels/Estevao/LevelEstevao.tscn"),
	preload("res://Kelcia Level/scene/level.tscn"),
]

var next_level: BaseLevel = null
var points = 0

var level_start = [
	"ESCOVA",
	"MATE BUGS",
	"NÃO LEVE PATADA",
	"MARIO?",
	"CAFÉZINHO"
]

var level_sound = [
	preload("res://Sounds/boca.wav"),
	preload("res://All/pristart.wav"),
	preload("res://All/neidebad3.wav"),
	preload("res://Sounds/Estevao/ai sim.wav"),
	preload("res://All/kelciastart.wav"),
]
var level_start_index = 0

@onready var transition_scene: TransitionScene = $TransitionScene

func _ready():
	MainAudio.stream = load("res://Sounds/starbolt.mp3")
	MainAudio.play()
	# Ensure RichTextLabel is ready for custom effect + BBCode
	var rtl := transition_scene.TextLabel
	rtl.bbcode_enabled = true
	var fx := WaveJumpEffect.new()
	# (optional) tweak effect defaults here
	# fx.amplitude = 16.0
	# fx.period = 0.55
	# fx.spread = 0.12
	# fx.sharpness = 1.7
	rtl.custom_effects = [fx]

	# Now assign BBCode (**use text or bbcode_text; both work when bbcode_enabled is true**)
	rtl.text = "[wave_jump]Preparado?[/wave_jump]"
	# Alternatively:
	# rtl.bbcode_text = "[wave_jump]Preparado?[/wave_jump]"

	TransitionTimer.wait_time = 5
	TransitionTimer.start()
	transition_going = true
	
	await get_tree().create_timer(4.0).timeout
	Audio.stream = level_sound[level_start_index]
	Audio.play()
	return

func _process(delta: float) -> void:	
	transition_scene.BG.color = "cc7731"
	if TransitionTimer.time_left < 1.0 and transition_going:
		transition_scene.BG.color = "1c0200"
		transition_scene.TextLabel.text = apply_size(level_start[level_start_index])
	
	if current_level_instance != null:
		if current_level_instance.is_finished and is_on_level:
			
			_on_level_timer_timeout()
	return

func load_level() -> void:
	current_level = level_list[current_level_index]
	current_level_instance = await TransitionLayer.transition_to(current_level, self)
	return

func _on_transition_timer_timeout() -> void:
	# Transition timer finished, now go to level
	if current_level_index + 1 == level_list.size():
		difficulty += 1
	
	current_level_index = (current_level_index + 1) % level_list.size()
	is_on_level = true
	TransitionTimer.stop()
	
	# Load the level
	await load_level()
	
	LevelTimer.wait_time = current_level_instance.wait_time
	LevelTimer.start()
	TransitionTimer.stop()
	transition_going = false
	pass # Replace with function body.

func _on_level_timer_timeout() -> void:
	# Level timer finished, now go to transition
	is_on_level = false
	LevelTimer.stop()
	level_start_index = (level_start_index + 1) % level_start.size()
	
	handle_level_result()
	
	# Transition out - slide current scene left off-screen
	await TransitionLayer.transition_out()
	
	TransitionTimer.start()
	transition_going = true
	
	await get_tree().create_timer(4.0).timeout
	Audio.stream = level_sound[level_start_index]
	Audio.play()
	pass # Replace with function body.

func handle_level_result() -> void:
	points = points + 1
	if current_level_instance.is_success:
		var random_success_text = current_level_instance.success_texts[randi() % current_level_instance.success_texts.size()]
		var random_success_audio = current_level_instance.success_sounds[randi() % current_level_instance.success_sounds.size()]
		if points >= 15:
			get_tree().change_scene_to_file("res://Scenes/Credits.tscn")
			return
		transition_scene.TextLabel.text = random_success_text
		var newLabel = apply_wave_jump(random_success_text)
		await get_tree().create_timer(1.0).timeout
		transition_scene.TextLabel.text = newLabel
		Audio.stream = random_success_audio
		Audio.play()
	else:
		var random_fail_text = ""
		if current_level_instance.fail_texts.size() > 0:
			random_fail_text = current_level_instance.fail_texts[randi() % current_level_instance.fail_texts.size()]
		else:
			random_fail_text = "Falha!"  # fallback padrão

		var random_fail_audio = null
		if current_level_instance.fail_sounds.size() > 0:
			random_fail_audio = current_level_instance.fail_sounds[randi() % current_level_instance.fail_sounds.size()]

		if transition_scene:
			transition_scene.TextLabel.text = random_fail_text
		lives -= 1
		if lives == 0:
			get_tree().change_scene_to_file("res://Scenes/GameOver.tscn")
			return
		if points >= 15:
			get_tree().change_scene_to_file("res://Scenes/Credits.tscn")
			return
		transition_scene.Lives.text = str(lives)
		var newLabel = apply_wave_jump(random_fail_text)
		await get_tree().create_timer(1.0).timeout
		transition_scene.TextLabel.text = newLabel
		Audio.stream = random_fail_audio
		Audio.play()
	
	return

func apply_wave_jump(label: String) -> String:
	var txt := label.strip_edges()
	label = "[wave_jump]" + txt + "[/wave_jump]"
	return label

func apply_size(label: String) -> String:
	var txt := label.strip_edges()
	label = "[font_size=80]" + txt + "[/font_size]"
	return label
