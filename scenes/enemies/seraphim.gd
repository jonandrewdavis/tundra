extends CharacterBody3D

# TODO: Extend from base enemy class?
@onready var animation_player = $blockbench_export/AnimationPlayer

const SPEED = 5.0

var target = Vector3.ZERO

var health = 20.0

func _ready():
	add_to_group("targets")
	animation_player.play("fly")

func _physics_process(_delta: float) -> void:
	# Add the gravity.
	#if not is_on_floor():
		#velocity += get_gravity() * delta

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = global_position.direction_to(target).normalized()

	if direction:
		# Move in towards center
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			velocity.y = direction.y * SPEED
			if global_position.distance_to(target) < 15.0:
				velocity = Vector3.ZERO
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		velocity.y = move_toward(velocity.y, 0, SPEED)

	move_and_slide()

func hit(_damage):
	if health > 0:
		health = health - _damage
	else:
		die()

func die():
	$CollisionShape3D.disabled = true
	animation_player.play_backwards('spawn')
	var animation_length = animation_player.get_animation('spawn').length
	animation_player.speed_scale = 4.0
	await get_tree().create_timer(animation_length / 2).timeout
	queue_free()
