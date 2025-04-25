@tool
# Dead
extends MovementState

func tick(delta, _tick, _is_fresh):
	stop_player(delta)

#func display_enter(_previous: RewindableState, _tick: int):
	#parent._animation_player.active = false
	#parent.bones.active = true
	#parent.bones.physical_bones_start_simulation()
	#
#func display_exit(_previous: RewindableState, _tick: int):
	#parent._animation_player.active = true
	#parent.bones.active = false
	#parent.bones.physical_bones_stop_simulation()
