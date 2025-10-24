extends CharacterBody2D

class_name EstevaoPlayer

@export var Level: LevelEstevao
var speed = 200

func _ready() -> void:
	print("EstevaoPlayer ready")
	return

func _physics_process(delta: float) -> void:
	# Handle movement
	if Input.is_action_pressed("right"):   
		velocity.x = speed
		velocity.y = 0
	elif Input.is_action_pressed("left"):
		velocity.x = -speed
		velocity.y = 0
	elif Input.is_action_pressed("up"):
		velocity.y = -speed
		velocity.x = 0
	elif Input.is_action_pressed("down"):
		velocity.y = speed
		velocity.x = 0
	else:
		velocity.y = 0
		velocity.x = 0
	
	# Move and check for collisions
	move_and_slide()
	
	# Check for mushroom collisions
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.name.to_lower().contains("mushroom"):
			collider.queue_free()
			Level.mushrooms.pop_front()
			
			if len(Level.mushrooms) == 0:
				Level.Audio.play()
				Level._success()
	
	return
