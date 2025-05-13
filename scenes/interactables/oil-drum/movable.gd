extends RigidBody3D
class_name Movable

@export var label: String
@export var enable_pickup: bool

var holder: Marker3D

func _ready() -> void:
	set_collision_layer_value(8, true)
	#if not multiplayer.is_server():
	#set_physics_process(false)
	#set_process(false)
	
	NetworkTime.on_tick.connect(_apply_tick)

# TODO: This could be more straightforward. Kind of a mess
func interact(player: Player) -> bool:
	if enable_pickup && not holder:
		holder = player._camera_input.holder
		return true
	elif enable_pickup && holder:
		# Only allow removal of holding from the player holding.
		if holder.get_multiplayer_authority() == player._camera_input.holder.get_multiplayer_authority():
			holder = null
			return true
		else:
			return false
	
	# Rejects attempts to interact
	return false
#
#func _physics_process(_delta: float) -> void:
	#if enable_pickup && holder:
		#if global_position.distance_to(holder.global_position) > 4.0:
			#holder = null
			## TODO: Emit signal to tell player to DROP IT.
			#return
		#
		#var a = global_transform.origin # here,
		#var b = holder.global_transform.origin # there
		#set_linear_velocity(lerp(linear_velocity, (b - a) * 10, 0.5))

func _apply_tick(_delta, _tick):
	if enable_pickup && holder:
		if global_position.distance_to(holder.global_position) > 4.0:
			holder = null
			# TODO: Emit signal to tell player to DROP IT.
			return
		
		var a = global_transform.origin # here,
		var b = holder.global_transform.origin # there
		set_linear_velocity(lerp(linear_velocity, (b - a) * 10, 0.5))
