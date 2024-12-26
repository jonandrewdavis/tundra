extends RigidBody3D

@export var replicated_position : Vector3
@export var replicated_rotation : Vector3
@export var replicated_linear_velocity : Vector3
@export var replicated_angular_velocity : Vector3

@onready var rope_end = $Rope/End

@onready var idle_timer = $IdleTimer
var speed: float = 0.2

var player_attached: CharacterBody3D = null
@export var is_player_attached_sync = false


# TODO: Is this necessary
#func _enter_tree():
	#set_multiplayer_authority(1)

## Called when the node enters the scene tree for the first time.
#func _ready():
	#if not multiplayer.is_server():
		#set_process(false)
		#set_physics_process(false)
	#
	#add_to_group("interactable")
	#collision_layer = 9
	#
## TODO: This should be tick? 
#
#func _integrate_forces(state):
	#if is_multiplayer_authority():
		#if not player_attached:
			#var down = 0.0
			#if $CartCenterCast.is_colliding() == false:
				#down = -1.0
			#var down_dir: Vector3 = (basis * Vector3(0, down, 0)).normalized()
			#state.linear_velocity = 3.0 * down_dir
			##state.angular_velocity = 10 * target_dir
#
			#replicated_position = position
			#replicated_rotation = rotation
			#replicated_linear_velocity = state.linear_velocity
			#replicated_angular_velocity = state.angular_velocity
			#return
#
		#var target_position = player_attached.global_transform.origin
#
		#var forward_local_axis: Vector3 = Vector3(0, 0, 1)
		#var forward_dir: Vector3 = (basis * forward_local_axis).normalized()
		#var target_dir: Vector3 = (target_position - transform.origin).normalized()
		#var local_speed: float = clampf(speed, 0, acos(forward_dir.dot(target_dir))) / 4
		#if forward_dir.dot(target_dir) > 1e-4:
			#state.angular_velocity = local_speed * forward_dir.cross(target_dir * Vector3(1.0, 1.0, 1.0)) / state.step / 2
			#
		#var distance_to_target = transform.origin.distance_to(target_position)
		#if distance_to_target > 7.0:
			#state.linear_velocity = 0.1 * target_dir / state.step
		#elif distance_to_target > 5.5:
			#state.linear_velocity = 0.05 * target_dir / state.step
		#elif distance_to_target < 3.5:
			#state.linear_velocity = 0.05 * -target_dir / state.step
#
		#replicated_position = position
		#replicated_rotation = rotation
		#replicated_linear_velocity = state.linear_velocity
		#replicated_angular_velocity = state.angular_velocity
	#else:
		#state.linear_velocity = replicated_linear_velocity
		#state.angular_velocity = replicated_angular_velocity
		#position = replicated_position
		#rotation = replicated_rotation

var prev_position = Vector3.ZERO

func _process(_delta):
	if not is_multiplayer_authority():
		return

func activate(_activated_player: CharacterBody3D):
	pass
