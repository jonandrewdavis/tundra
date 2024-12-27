extends RigidBody3D

@export var replicated_position : Vector3
@export var replicated_rotation : Vector3
@export var replicated_linear_velocity : Vector3
@export var replicated_angular_velocity : Vector3

# TODO: Is this necessary
#func _enter_tree():
	#set_multiplayer_authority(1)

## Called when the node enters the scene tree for the first time.
func _ready():
	if not multiplayer.is_server():
		set_process(false)
		set_physics_process(false)
	else:
		contact_monitor = true
		max_contacts_reported = 5

func _integrate_forces(state):
		if is_multiplayer_authority():
			replicated_position = position
			replicated_rotation = rotation
			replicated_linear_velocity = state.linear_velocity
			replicated_angular_velocity = state.angular_velocity
		else:
			state.linear_velocity = replicated_linear_velocity
			state.angular_velocity = replicated_angular_velocity
			position = replicated_position
			rotation = replicated_rotation		

func _physics_process(_delta):
	for col in get_colliding_bodies():
		if col is CharacterBody3D:
			var normal_dir = col.global_position.direction_to(self.global_position).normalized()
			apply_central_impulse(normal_dir * col.velocity)
			apply_impulse(normal_dir * 0.5, get_position())

			#col.velocity = col.velocity + linear_velocity
			#print(col.velocity)
