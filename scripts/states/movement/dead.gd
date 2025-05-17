@tool
# Dead
extends MovementState


func tick(delta, _tick, _is_fresh):
	stop_player(delta)

func enter(_previous: RewindableState, _tick: int):
	parent.bones.active = true
	parent._animation_player.active = false
	parent.bones.physical_bones_start_simulation()
	await get_tree().process_frame
	if multiplayer.is_server():
		parent.ragdoll_on_client.rpc()

func exit(_previous: RewindableState, _tick: int):
	parent.global_position = Hub.castle.global_position + Vector3(randi_range(-2, 2), 0.8, randi_range(-2, 2)) * 10 + Vector3(0.0, 0.0, -20.0)
	parent._tick_interpolator.teleport()

	parent.bones.active = false
	parent._animation_player.active = true
	parent.bones.physical_bones_stop_simulation()

	await get_tree().process_frame
	if multiplayer.is_server():
		parent.ragdoll_on_client.rpc()
