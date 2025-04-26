@tool
# Idle
extends MovementState

func tick(delta, _tick, _is_fresh):
	rotate_player_model(delta)
	stop_player(delta)
	check_for_ragdoll()
