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
	
	if !direction:
		parent.velocity = parent.velocity.move_toward(Vector3.ZERO, parent.FRICTION * delta)
		return

	if position_target:
		parent.velocity = parent.velocity.move_toward(position_target, parent.ACCELERATION * delta)

	#if mov_direction != Vector2.ZERO:
		#velocity = velocity.move_toward(mov_direction * max_speed, acceleration * delta)
	#else:
		#velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	#else:
		#parent.velocity.x = move_toward(parent.velocity.x, 0, speed)
		#parent.velocity.z = move_toward(parent.velocity.z, 0, speed)
	#if horizontal_velocity:
		#parent.velocity.x = move_toward(horizontal_velocity.x, parent.ACCELERATION * delta) 
		#parent.velocity.z = move_toward(horizontal_velocity.z, parent.ACCELERATION * delta) 
#
		#parent.velocity.z = horizontal_velocity.z
	# NOTE: Removed from template to add friction in IdleState
	#else:
		#parent.velocity.x = move_toward(parent.velocity.x, 0, speed)
		#parent.velocity.z = move_toward(parent.velocity.z, 0, speed)

	# https://foxssake.github.io/netfox/netfox/tutorials/rollback-caveats/#characterbody-velocity
	parent.velocity *= NetworkTime.physics_factor
	parent.move_and_slide()
	parent.velocity /= NetworkTime.physics_factor
