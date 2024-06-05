extends Area2D

var speed : int = 200
var direction : int = 1
var attack_damage := 1.0
var knockback_power := 30


func _physics_process(delta):
	move_local_x(direction * speed * delta)


func _on_visible_on_screen_enabler_2d_screen_exited():
	queue_free()


func _on_body_entered(body):
	queue_free()
	if body.has_method("damage"):
		body.damage(attack_damage, knockback_power, global_position)
