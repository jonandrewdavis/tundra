# Ragdoll
extends MovementState

func tick(delta, _tick, _is_fresh):
	move_towards_ragdoll(delta)
	move_player(delta)

	if parent.bones.active == false:
		force_update_is_on_floor()
		if parent.is_on_floor():	
			if get_movement_input() != Vector2.ZERO:
				state_machine.transition(&"MoveState")
			elif get_jump():
				state_machine.transition(&"JumpState")
		else:
			state_machine.transition(&"FallState")

func move_towards_ragdoll(_delta):
	pass
	#if parent.bones.active == true:
		## TODO: is zeroing out Y the correct action?
		#var parent_pos = parent.global_position * Vector3(1.0, 2.0, 1.0)
		#var chest_pos = parent.chest.global_position * Vector3(1.0, 2.0, 1.0)
		#if parent_pos.distance_to(chest_pos) > 1.0:
			#var direction_to_bones = parent_pos.direction_to(chest_pos).normalized()
			#parent.velocity.x = direction_to_bones.x * parent.SPEED
			#parent.velocity.z = direction_to_bones.z * parent.SPEED
		#else:
			#parent.velocity.x = move_toward(parent.velocity.x, 0, parent.SPEED)
			#parent.velocity.z = move_toward(parent.velocity.z, 0, parent.SPEED)
	
