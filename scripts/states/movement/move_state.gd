extends MovementState

func tick(delta, _tick, _is_fresh):
	rotate_player_model(delta)
	move_player(delta)

	force_update_is_on_floor()
	if parent.is_on_floor():
		if get_movement_input() == Vector2.ZERO:
			state_machine.transition(&"IdleState")
		elif get_jump():
			state_machine.transition(&"JumpState")
	else:
		state_machine.transition(&"FallState")


func move_player(delta: float, speed = parent.WALK_SPEED):
	# NOTE: This state implements it's own "move_player"
	# Any state with controls needs this constant force! 
	#apply_constant_force()

	var input_dir : Vector2 = get_movement_input()
	
	# Based on https://github.com/godotengine/godot-demo-projects/blob/4.2-31d1c0c/3d/platformer/player/player.gd#L65
	var direction = (camera_input.camera_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var position_target = direction * speed
	
	# Run speed is not applied to jump (see get_run)
	if get_run():
		position_target *= SPRINT_SPEED_MODIFIER
	#
	if position_target:
		parent.velocity = parent.velocity.move_toward(position_target, parent.ACCELERATION * delta)


	force_update_is_on_floor()
	if not parent.is_on_floor():
		parent.velocity.y -= gravity * delta

	var platform_velocity := Vector3.ZERO
	var collision_result := KinematicCollision3D.new()
	if parent.test_move(parent.global_transform, Vector3.DOWN * delta, collision_result):
		var collider := collision_result.get_collider()
		if collider is MovingCastle:
			var platform := collider as MovingCastle
			platform_velocity = platform.get_velocity()

	#var direction = Vector3(input.movement.x, 0, input.movement.z).normalized()
	#if direction:
		#parent.velocity.x = direction.x * speed
		#parent.velocity.z = direction.z * speed
	#else:
		#parent.velocity.x = move_toward(parent.velocity.x, 0, speed)
		#parent.velocity.z = move_toward(parent.velocity.z, 0, speed)


	# https://foxssake.github.io/netfox/netfox/tutorials/rollback-caveats/#characterbody-velocity
	parent.velocity += platform_velocity
	parent.velocity *= NetworkTime.physics_factor
	parent.move_and_slide()
	parent.velocity /= NetworkTime.physics_factor
	parent.velocity -= platform_velocity
