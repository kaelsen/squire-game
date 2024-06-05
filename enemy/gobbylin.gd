extends CharacterBody2D

enum States{
	Wander,
	Chase
}

@export var wander_speed : float = 1500.0
@export var chase_speed : float = 3000.0
#@export var knockback_power: int = 1200

var current_speed : float = 0.0
var player_found : bool = false
var player = null
var health = 3
var taking_damage = false
var stun = false

var knock_up := velocity.y - 2
var gravity : int = 15
var current_state = States.Wander

var attack_damage = 1.0
var knockback_power = 90.0


@onready var wall_ray_cast_left : RayCast2D = $WallCheck/WallRayCastLeft
@onready var wall_ray_cast_right : RayCast2D = $WallCheck/WallRayCastRight
@onready var floor_ray_cast_left : RayCast2D = $FloorCheck/FloorRayCastLeft
@onready var floor_ray_cast_right : RayCast2D = $FloorCheck/FloorRayCastRight
@onready var player_track_ray_cast :RayCast2D = $PlayerTrackerPivot/PlayerTrackRayCast
@onready var player_tracker_pivot : Node2D = $PlayerTrackerPivot
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var chase_timer : Timer = $ChaseTimer


func _ready():
	player = get_tree().get_first_node_in_group("player")
	#chase_timer.timeout.connect(_on_chase_timer_timeout)


func _physics_process(delta):
	if velocity.x != 0:
		animated_sprite_2d.play("walk")
	else:
		animated_sprite_2d.play("idle")
	if is_on_floor() == false:
		velocity.y += gravity
		
	if stun == true:
		animated_sprite_2d.play("hurt")
	handle_vision()
	track_player()
	handle_movement(delta)
	move_and_slide()
	handle_flip_h()
	#die()



func handle_movement(delta):
	if player == null:
		return
	elif stun == false:
		var direction = global_position - player.global_position
		if current_state == States.Wander:
			if floor_ray_cast_right.is_colliding() != true:
				current_speed = -wander_speed
			if floor_ray_cast_left.is_colliding() != true:
				current_speed = wander_speed
			if wall_ray_cast_right.is_colliding():
				current_speed = -wander_speed
			if wall_ray_cast_left.is_colliding():
				current_speed = wander_speed
		if current_state == States.Chase:
			if player_found == true:
				if direction.x < 0:
					current_speed = chase_speed
				else:
					current_speed = -chase_speed
		velocity.x = current_speed * delta
	elif stun == true:
		
		velocity *= (1 - delta) * 0.9


func handle_flip_h():
	var velocity_sign = sign(velocity.x)
	
	if velocity_sign < 0 and stun == false:
		animated_sprite_2d.flip_h = true
	elif velocity_sign > 0 and stun == false:
		animated_sprite_2d.flip_h = false


func track_player():
	if player == null:
		return
	else:
		var direction_to_player : Vector2 = Vector2(player.position.x, player.position.y)\
		- player_track_ray_cast.position
		
		player_tracker_pivot.look_at(direction_to_player)


func handle_vision():
	if player_track_ray_cast.is_colliding():
		var collision_result = player_track_ray_cast.get_collider()
		
		if collision_result != player:
			return
		else:
			current_state = States.Chase
			chase_timer.start(1)
			player_found = true
			
	else:
		player_found = false


func _on_chase_timer_timeout():
	if player_found == false:
		current_state = States.Wander


#func die():
	#if health <= 0:
		#queue_free()


func damage(attack_damage,knockback_power,attack_position):
	var tween := create_tween()
	var sprite_2d := $AnimatedSprite2D
	
	tween.tween_property(sprite_2d,"visible", false, .05)
	tween.tween_property(sprite_2d,"visible", true, .05)
	tween.tween_property(sprite_2d,"visible", false, .05)
	tween.tween_property(sprite_2d,"visible", true, .05)
		
	taking_damage = true
	stun = true
	health -= attack_damage
	$StunTimer.start()
	

	if health <= 0:
		
		stun = true
		$Hurtbox.monitoring = false
		tween.tween_property(sprite_2d, "scale", Vector2(1.0,0.0), 0.1)
		tween.finished.connect(queue_free)
	
	#print(health)
	velocity = (global_position - attack_position).normalized() * knockback_power
	

func _on_stun_timer_timeout():
	stun = false
	taking_damage = false


func _on_hurtbox_body_entered(body):
	if body.has_method("damage"):
		body.damage(attack_damage, knockback_power, global_position)
