@tool
# Idle
extends MovementState

func tick(delta, _tick, _is_fresh):
	if _is_fresh:
		print('ticking ragdoll')
	stop_player(delta)

func enter(_previous: RewindableState, _tick: int):
	print('should ENTER ragdoll')
	parent._animation_player.active = false
	parent.bones.active = true
	parent.bones.physical_bones_start_simulation()

func exit(_previous: RewindableState, _tick: int):
	print('should EXIT ragdoll')
	parent._animation_player.active = true
	parent.bones.active = false
	parent.bones.physical_bones_stop_simulation()
