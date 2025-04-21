# TODO: Beehave or some other behavioral tree when this state machine gets to be too much
# TODO: Random pauses between choosing another action? "Global cool down" like
# TODO: Assure this is completely server authoratative
# TODO: Perf test navigation agent to assure it doesn't consume to much CPU or cause FPS loss

extends CharacterBody3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
const FRICTION = 5
const ROTATION_SPEED = 2.0
const PROJECTILE_VELOCITY = 50.0

@export_category("Enemy Required Nodes")
@export var nav_agent: NavigationAgent3D
@export var search_box: Area3D
@export var animation_player: AnimationPlayer
@export var rigid_body_projectile: PackedScene
@export var GunOrigin: Marker3D
# TOOD: Weak points and eyeline
#@export var hit_box: Area3D
#@export var eyeline: Area3D 

@export_category("Enemy Stats")
@export var max_health = 10.0
@export var health = max_health
@export var max_speed = 5.0
@export var speed = max_speed

@onready var environment_container = get_tree().get_first_node_in_group("EnvironmentContainer")

var timer_target_aquire = Timer.new()
var timer_attack = Timer.new()

var target = null

# This enum lists all the possible states the character can be in.
enum States { IDLE, SEARCHING, CHASING, ATTACKING, HURTING, DODGING, DYING, EXPLODING }

# This variable keeps track of the character's current state.
var state: States = States.IDLE

func _ready(): 
	# TODO: enemies group as well.
	add_to_group("targets")

	# This enemy only runs on the server.
	# Only visuals and some rpcs are sync'd out.
	if not multiplayer.is_server():
		set_physics_process(false)
		set_process(false)
		return # Early return, no other code runs

	# Connect & create
	#hit_box.area_entered.connect(on_hitbox_area_entered)	
	animation_player.animation_finished.connect(on_animation_finished)
	search_box.body_entered.connect(on_search_box_body_entered)
	
	# Timers
	add_child(timer_target_aquire)
	timer_target_aquire.timeout.connect(retarget)
	timer_target_aquire.wait_time = 1.0
	timer_target_aquire.one_shot = false

	await get_tree().create_timer(0.2).timeout
	set_state(States.SEARCHING)

func _physics_process(delta: float) -> void:
	match state:
		States.CHASING, States.SEARCHING, States.HURTING:
			move_and_look(delta)
		States.ATTACKING:
			velocity = velocity.move_toward(Vector3.ZERO, FRICTION * delta)
		States.DYING:
			if not is_on_floor():
				velocity.y -= gravity * delta
			else: 
				set_state(States.EXPLODING)
				velocity = Vector3.ZERO

	move_and_slide()

func move_and_look(delta):
	var new_look_at
	var next_path_pos: Vector3 = nav_agent.get_next_path_position()

	if nav_agent.is_navigation_finished() == false:
		velocity = (next_path_pos - global_transform.origin).normalized() * speed
	else:
		velocity = velocity.move_toward(Vector3.ZERO, FRICTION * delta)

	#look
	if target:
		new_look_at = target.transform.origin
	else:
		# If "Target and up vectors are colinear" use "* Vector3.UP"
		# https://github.com/godotengine/godot/issues/53793 do * Vector3.UP
		new_look_at = next_path_pos * Vector3.UP

	var old = transform.basis.orthonormalized()
	look_at(new_look_at)
	var new = transform.basis.orthonormalized()
	transform.basis = lerp(old, new, ROTATION_SPEED * delta).orthonormalized()

func pick_patrol_destination():
	# TODO: Also pick a random nav_agent.path_height_offset 
	var map = NavigationServer3D.get_maps()[0]
	var random_point = NavigationServer3D.map_get_random_point(map, 1, false)
	nav_agent.set_target_position(random_point)

func set_state(new_state: States) -> void:
	var previous_state := state
	state = new_state

	#############
	# You can check both the previous and the new state to determine what to do when the state changes. 
	# This checks the previous state.
	if previous_state == States.SEARCHING:
		pass

	#############
	# Here, I check the new state.
	if state == States.SEARCHING:
		animation_player.play('fly')
		speed = 3.0
		pick_patrol_destination()
		pass

	if state == States.CHASING:
		if animation_player.is_playing() == false:
			animation_player.play('fly')
		timer_target_aquire.start()
		retarget()
		speed = 8.0
		# Start a "target aquisition" timer
		# every 0.5 seconds, try to get the new position for the player / target it's after
		pass
	
	if state == States.HURTING:
		animation_player.play('hurt')
		# interrupt whever we are doing to get hurt. Maybe a 33% chance to? 
		pass

	if state == States.ATTACKING:
		fire()

	if state == States.DYING:
		animation_player.play('dying')

	if state == States.EXPLODING:
		animation_player.pause()
		explode()
		
func explode():
	# TODO: Explode.
	animation_player.stop(true)
	await get_tree().create_timer(3.0).timeout
	queue_free()

# TODO: Would be nice to have an enum of animation names somehow
func on_animation_finished(animation_name):
	if animation_name == 'hurt':
		set_state(States.CHASING)
		# TODO: if no target, add it

# TODO: Should the entity receving damage handle it? It might make "critical hits" easier
# or, a hitbox can have a hit() function the bullet calls
func on_hitbox_area_entered(_area):
	pass

# WARNING: Do not type this as "CharacterBody3D". It must be more generic or it'll error.
func on_search_box_body_entered(body: Node3D):
	if body && body.is_in_group('players'):
		target = body
		set_state(States.CHASING)

func retarget():
	if target:
		nav_agent.target_desired_distance = 25.0
		nav_agent.set_target_position(target.global_transform.origin) # 1 vertical m up?
		fire()

# TODO: could call this "take_hit" or "get_hit" in a refactor
# basic_rigid_body_projectile calls "hit"
func hit(damage):
	if health - damage > 0:
		health = health - damage
		set_state(States.HURTING)
		print('health',health)
		# TODO: If no target, get closest player
	else:
		# TODO: "Ragdoll" the drone so it flops out of the sky better
		set_state(States.DYING)


func fire():
	var _proj = rigid_body_projectile.instantiate()
	var _target_point = target.global_position + Vector3(0.0, 0.7, 0.0)
	var _origin_point = GunOrigin.global_position
	var _direction = (_target_point - _origin_point).normalized()
	environment_container.add_child(_proj, true)
	_proj.position = _origin_point
	_proj.set_linear_velocity( _direction * PROJECTILE_VELOCITY)
	_proj.look_at(_target_point)	
	_proj.body_entered.connect(_on_player_hit.bind(_proj))

# TODO: Hit more than just players, damage to buildings, etc.
func _on_player_hit(body, _projectile):
	if body.is_in_group('players'):
		#print('DRONE HIT PLAYER')
		pass

	_projectile.queue_free()
