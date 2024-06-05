extends CharacterBody2D


@export var gravity = 0
@export var speed = 2500
@export var jump_force = 200

var player_chase = false
var player = null
var health = 1

@onready var animated_sprite = $AnimatedSprite2D


func _physics_process(delta):
	if is_on_floor() == false:
		velocity.y += gravity
		
	#var direction = 0
	#
	#if player_chase == true:
		#position += (player.position - position)/speed
	animated_sprite.play("idle")
	var direction = _get_player_direction()
	velocity = direction * speed * delta
	
	if velocity.x < 0:
		animated_sprite.flip_h = true
	else:
		animated_sprite.flip_h = false
	_die()
	move_and_slide()

func _on_detection_body_entered(body):
	player = body
	player_chase = true


#func _on_detection_body_exited(body):
	#player = null
	#player_chase = false
	

func _get_player_direction():
	var player_node = get_tree().get_first_node_in_group("player")
	if player_node != null:
		return(player_node.global_position - global_position).normalized()
	return Vector2.ZERO

func _die():
	if health <= 0:
		queue_free()
