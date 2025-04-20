@tool
# Ragdoll
extends MovementState

func tick(delta, _tick, _is_fresh):
	stop_player(delta)
	move_player(delta)
	check_for_ragdoll()
