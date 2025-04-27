@tool
# Idle
extends MovementState

func tick(_delta, _tick, _is_fresh):
	stop_player(_delta)

	if parent.bones.active == false:
		state_machine.transition(&"Idle")

#func enter(_previous: RewindableState, _tick: int):
	#parent.bones.physical_bones_start_simulation()
#
#func exit(_previous: RewindableState, _tick: int):
	#parent.bones.physical_bones_stop_simulation()
