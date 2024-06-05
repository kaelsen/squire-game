extends CharacterBody2D

signal hit

enum States{
	Idle,
	Moving,
	Combat,
	Jumping
	}


const DASH_SPEED = 12000


@export var gravity : int = 15
@export var speed : float
@export var jump_force : float = 290
#@export var ghost_node : PackedScene #dash afterimage
@export var knockback_power := 190
@export var health = 5
@export var attack_damage := 2.0
var taking_damage := false


var current_state = States.Idle

var dashing : bool = false
var can_dash : bool = true
var can_jump : bool = true
var double_jump : int = 2
var attacking : bool = false
var attack_combo : int = 2
var can_attack : bool = true
var can_combo : bool
var character_active : bool = true



var enemy = preload("res://enemy/gobbylin.tscn")
var arrow_scene = preload("res://player/projectile.tscn")
@onready var melee_attack = $MeleeAttack
@onready var animated_sprite = $AnimatedSprite2D
@onready var dash_particles = $DashParticles
@onready var arrow_container = $ArrowsContainer
#@onready var animation_player = $AnimationPlayer

func _ready():
	animated_sprite.animation_finished.connect(_on_animated_sprite_2d_animation_finished)

func _physics_process(delta):
	if Input.is_action_just_pressed("melee"):
		if current_state == States.Idle || current_state == States.Moving || current_state == States.Jumping:
			_attack()
		elif current_state == States.Combat:
			_attack_combo()
		
		
	elif Input.is_action_just_pressed("ranged"):
		if current_state == States.Idle || current_state == States.Moving || current_state == States.Jumping:
			current_state = States.Combat
			
			_ranged()
		

	if is_on_floor() == false:
		velocity.y += gravity
	
	
	_player_controller(delta)
	move_and_slide()
	



func _player_controller(delta):
	if character_active == true:
		var direction = Input.get_axis("left","right")
		if character_active == true:
			if Input.is_action_just_pressed("jump") and is_on_floor():
				current_state = States.Jumping
				_jump(jump_force)
				#can_jump = false
				
			if attacking != true and direction != 0:
				animated_sprite.flip_h = (direction == -1)
		else:
			velocity *= (1 - delta) * 0.9
			
		if current_state == States.Combat and is_on_floor():
			speed = 2000
		else:
			speed = 4000
			

		var movement = direction * speed
		
		if dashing == false:
			velocity.x = movement * delta
		
		if dashing == true:
			velocity.x = direction * DASH_SPEED * delta
			#velocity.y = 0 #stays in the air while dashing

		
		if Input.is_action_just_pressed("dash") and can_dash:
			
			dashing = true
			can_dash = false
			$DashTimer.start()
			$DashCooldown.start()
			dash_particles.emitting = true
			
		_animations(direction)
	
	
func _animations(direction):
	if attacking == false:
		if is_on_floor():
			if direction == 0:
				current_state = States.Idle
				animated_sprite.play("idle")
			else:
				current_state = States.Moving
				animated_sprite.play("run")
		
		elif velocity.y <= 0:
			animated_sprite.play("jump")
		else:
			animated_sprite.play("fall")
			
		if dashing == true:
			animated_sprite.play("flash")
			var tween := create_tween()
			var sprite_2d := $AnimatedSprite2D
			
			tween.tween_property(sprite_2d, "scale", Vector2(1.2,0.75), 0.02)
	
func _jump(force):
	velocity.y = -force


func _on_dash_timer_timeout():
	dashing = false
	dash_particles.emitting = false
	var tween := create_tween()
	var sprite_2d := $AnimatedSprite2D
	
	tween.tween_property(sprite_2d, "scale", Vector2(1.0,1.0), 0.04)


func _on_dash_cooldown_timeout():
	can_dash = true


func _attack():
	current_state = States.Combat
	if animated_sprite.flip_h == true:
		melee_attack.position.x = -10
	else:
		melee_attack.position.x = 10
	if can_attack == true:
		attacking = true
		can_combo = true
		
		melee_attack.monitoring = true
		attack_combo -= 1
		animated_sprite.play("attack1")
		#animation_player.play("attack")


func _attack_combo():
	if animated_sprite.flip_h == true:
		melee_attack.position.x = -10
	else:
		melee_attack.position.x = 10
		
	if can_attack == true and can_combo == true:
		attacking = true
		melee_attack.monitoring = true
		can_combo = false
		#if attack_combo == 1:
		animated_sprite.play("attack2")
		#if attack_combo <= 0:
			#attack_combo = 2
		


func _ranged():
	if can_attack == true:
		var direction : int = 0
		var arrow_instance = arrow_scene.instantiate()
		
		attacking = true
		
		animated_sprite.play("ranged")
		arrow_container.add_child(arrow_instance)
		arrow_instance.global_position = global_position
		arrow_instance.global_position.y += 3
		
		if direction <= 0 and animated_sprite.flip_h == true:
			arrow_instance.rotation_degrees = 180


func _on_animated_sprite_2d_animation_finished():
	current_state = States.Idle
	melee_attack.monitoring = false
	if animated_sprite.animation == "attack1":
		attacking = false
		melee_attack.monitoring = false
	if animated_sprite.animation == "attack2":
		attacking = false
		melee_attack.monitoring = false
	if animated_sprite.animation == "ranged":
		attacking = false


func _on_melee_attack_body_entered(body):
	if body.has_method("damage"):
		body.damage(attack_damage, knockback_power, global_position)


func damage(attack_damage,knockback_power,attack_position):
	health -= attack_damage
	character_active = false
	$StunTimer.start()
	if health <= 0:
		var tween := create_tween()
		var sprite_2d := $AnimatedSprite2D
		
		tween.tween_property(sprite_2d, "scale", Vector2(0.0,0.0), 0.2)
		tween.finished.connect(queue_free)
		character_active = false
		
	taking_damage = true
	#print(health)
	velocity = (global_position - attack_position).normalized() * knockback_power



func _on_stun_timer_timeout():
	taking_damage = false
	character_active = true
