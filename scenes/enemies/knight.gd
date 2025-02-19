extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var target = Vector3.ZERO
var health = 20.0
var at_target = false
@onready var animation_player = $Solus_the_knight/AnimationPlayer

func _ready():
	add_to_group("targets")
	animation_player.play("knight_walk_in_place")
	look_at(target)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	var direction = global_position.direction_to(target).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		if global_position.distance_to(target) < 8.0:
			velocity = Vector3.ZERO
			if at_target == false:
				at_target = true
				stop_walk()
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func stop_walk():
	animation_player.play("knight_idle")

func hit(_damage):
	if health > 0:
		health = health - _damage
	else:
		die()

func die():
	$BodyCollisionShape.disabled = true
	animation_player.play('knight_left_attacked_fall')
	var animation_length = animation_player.get_animation('knight_left_attacked_fall').length
	await get_tree().create_timer(animation_length).timeout
	queue_free()
