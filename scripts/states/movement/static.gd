@tool
# Static
extends MovementState

var is_open: bool = false

# TODO: Interact?

func tick(delta, _tick, _is_fresh):
	stop_player(delta)

	if get_main_menu_input() == true && is_open == true:
		print("LEAVING")
		state_machine.transition(&"Idle")

func enter(_previous: RewindableState, _tick: int):
	print("ENTEREDw")
	is_open = true
	parent.main_menu_signal.emit(true)

func exit(_previous: RewindableState, _tick: int):
	parent.main_menu_signal.emit(false)
