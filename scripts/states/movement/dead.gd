@tool
# Dead
extends MovementState

func tick(delta, _tick, _is_fresh):
	stop_player(delta)
