extends BaseLevel

@export var choice1: Choice
@export var choice2: Choice
@export var choice3: Choice
@export var choice4: Choice

@onready var patada: RichTextLabel = $Control/Patada
@onready var neide: Sprite2D = $Neide

@onready var Audio: AudioStreamPlayer = $AudioStreamPlayer
@onready var AudioVictory: AudioStreamPlayer = $AudioStreamPlayer2

var chosen = false

func _ready() -> void:
	Audio.stream = load("res://Sounds/death.wav")
	Audio.play()
	Audio.stream_paused = true
	AudioVictory.stream = load("res://Sounds/round_end.wav")
	AudioVictory.play()
	AudioVictory.stream_paused = true
	success_sounds = [
		preload("res://All/neidegood1.wav"),
		preload("res://All/neidegood2.wav"),
	]
	
	fail_sounds = [
		preload("res://All/neidebad1.wav"),
		preload("res://All/neidebad2.wav"),
	]
	difficulty = LevelManager.difficulty
	if difficulty == 1:
		patada.text = "Você chegou atrasado denovo?"
		choice1.ChoiceText.text = "O transito tava caótico hoje..."
		choice2.ChoiceText.text = "Pontualidade é um conceito capitalista"
		choice3.ChoiceText.visible = false
		choice4.ChoiceText.visible = false
		return
	
	if difficulty == 2:
		patada.text = "Gostei dessa roupa, ta diferente!"
		choice1.ChoiceText.text = "Diferente tipo, elogio ou crítica?"
		choice2.ChoiceText.text = "To bonito né?"
		choice3.ChoiceText.text = "Quis tentar uma coisa nova"
		choice4.ChoiceText.visible = false
		return
	
	if difficulty == 3:
		patada.text = "Você sumiu! Nem deu mais sinal de vida"
		choice1.ChoiceText.text = "Sumir é um talento, difícil é reaparecer"
		choice2.ChoiceText.text = "Achei que não ia sentir falta"
		choice3.ChoiceText.text = "Tava tentando fugir da conversa"
		choice4.ChoiceText.text = "Foi correria demais esses dias"
		return
	
	if difficulty == 3:
		return

func _process(delta: float) -> void:
	if is_fail:
		Audio.stream_paused = false
		if difficulty == 1:
			patada.text = "E irresponsabilidade é o que? Filosofia de vida?"
		if difficulty == 2:
			patada.text = "Depende de quem olha..."
		if difficulty == 3:
			patada.text = "Na próxima nem precisa aparecer"
		
		neide.texture = load("res://All/neide2.png")
	
	if is_success:
		AudioVictory.stream_paused = false
		if difficulty == 1:
			patada.text = "Aah acontece..."
		if difficulty == 2:
			patada.text = "Ficou bom!"
		if difficulty == 3:
			patada.text = "Que bom te ver de volta!"
			
		neide.texture = load("res://All/neide1.png")
		
	if chosen:
		return

	if Input.is_action_just_pressed("up"):
		delete_choices(choice2)
		delete_choices(choice3)
		delete_choices(choice4)
		chosen = true
		
		if difficulty == 1:
			return _success()
		
		return _fail()

	if Input.is_action_just_pressed("right"):
		delete_choices(choice1)
		delete_choices(choice3)
		delete_choices(choice4)
		chosen = true
		
		
		return _fail()

	if Input.is_action_just_pressed("down"):
		delete_choices(choice1)
		delete_choices(choice2)
		delete_choices(choice4)
		chosen = true
		
		if difficulty == 2:
			return _success()
		
		return _fail()

	if Input.is_action_just_pressed("left"):
		delete_choices(choice1)
		delete_choices(choice2)
		delete_choices(choice3)
		chosen = true
		
		if difficulty == 3:
			return _success()
		
		return _fail()

	
	return


func delete_choices(choice: Choice) -> void:
	if choice != null:
		choice.ChoiceText.visible = false
