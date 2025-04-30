@tool
# Idle
extends MovementState

func tick(delta, _tick, _is_fresh):
	rotate_player_model(delta)
	stop_player(delta)
	#check_for_ragdoll()

	if parent.bones.active == true:
		state_machine.transition(&"Ragdoll")

	force_update_is_on_floor()
	if parent.is_on_floor():
		if get_jump():
			state_machine.transition(&"Jump")
		elif get_movement_input() == Vector2.ZERO:
			state_machine.transition(&"Idle")
		else: 
			state_machine.transition(&'Move')
	else:
		state_machine.transition(&"Fall")
