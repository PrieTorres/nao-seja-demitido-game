extends Node2D

class_name BaseLevel

var difficulty = 0
var success_chance = 50
var is_success = false
var is_fail = false
var is_finished = false

@export var wait_time = 5.0

var LevelManager: LevelManager

# Timer for delay
@onready var delay_timer: Timer

@export var start_sound = preload("res://Sounds/Estevao/ai sim.wav")

@export var success_sounds = []
@export var success_texts: Array[String] = ["Boa!!", "Vencemo!"]

@export var fail_sounds = []
@export var fail_texts: Array[String] = ["Num deu...", "Paia..."]

# Signals
signal success
signal fail

# Functions
func _success() -> void:
	is_success = true
	is_fail = false
	success.emit()

func _fail() -> void:
	is_success = false
	is_fail = true
	fail.emit()
