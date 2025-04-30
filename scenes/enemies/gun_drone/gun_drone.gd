# TODO: Beehave or some other behavioral tree when this state machine gets to be too much
# TODO: Random pauses between choosing another action? "Global cool down" like
# TODO: Assure this is completely server authoratative
# TODO: Perf test navigation agent to assure it doesn't consume to much CPU or cause FPS loss

extends CharacterBody3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
const FRICTION = 2
const ROTATION_SPEED = 2.0
const PROJECTILE_VELOCITY = 50.0

@export_category("Enemy Required Nodes")
@export var nav_agent: NavigationAgent3D
@export var search_box: Area3D
@export var animation_player: AnimationPlayer
@export var gun_origin: Marker3D
@export var health_system: HealthSystem
@export var nav: NavigationSystem
@export var rigid_body_projectile: PackedScene

# TODO: Weak points and eyeline
# TODO: Give up chase 
#@export var hit_box: Area3D
#@export var eyeline: Area3D 

@export_category("Enemy Stats")
@export var max_health = 10.0
@export var health = max_health
@export var max_speed = 5.0
@export var speed = max_speed
@export var attack_value: int = 10

@onready var environment_container = get_tree().get_first_node_in_group("EnvironmentContainer")

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
		# CRITICAL: Having this big search area enabled causes
		# HUGE frame rate issues for some reason
		$SearchBox/CollisionShape3D.disabled = true
		# CAUTION: Trying to disable process on clients can cause MultiplayerSyncronizer issues.
		#set_process(false)

		return # Early return, no other code runs

	# Connect & create
	animation_player.animation_finished.connect(on_animation_finished)
	search_box.body_entered.connect(on_search_box_body_entered)
	search_box.body_exited.connect(on_search_box_body_exited)
	
	# Health
	health_system.hurt.connect(on_hurt)
	health_system.death.connect(on_death)
	
	# Nav
	nav.give_up_signal.connect(give_up)

	await get_tree().create_timer(0.2).timeout
	set_state(States.SEARCHING)

func _physics_process(delta: float) -> void:
	match state:
		States.CHASING, States.SEARCHING, States.HURTING:
			move_and_look(delta)
		#States.ATTACKING:
			#velocity = velocity.move_toward(Vector3.ZERO, FRICTION * delta)
		States.DYING:
			if not is_on_floor():
				velocity.y -= gravity * delta
			else:
				set_state(States.EXPLODING)
				velocity = Vector3.ZERO
	
	move_and_slide()

func move_and_look(delta):
	var new_look_at
	if nav_agent.is_navigation_finished() == false:
		velocity = (nav.next_path_pos - global_transform.origin).normalized() * speed
	else:
		velocity = velocity.move_toward(Vector3.ZERO, FRICTION * delta)

	#look
	if target:
		new_look_at = target.transform.origin
	else:
		# If "Target and up vectors are colinear" use "* Vector3.UP"
		# https://github.com/godotengine/godot/issues/53793 do * Vector3.UP
		new_look_at = nav.next_path_pos * Vector3.UP 

	var old = transform.basis.orthonormalized()
	look_at(new_look_at)
	var new = transform.basis.orthonormalized()
	transform.basis = lerp(old, new, ROTATION_SPEED * delta).orthonormalized()

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
		target = null
		animation_player.play('fly')
		speed = 3.0
		nav.pick_patrol_destination()
		pass

	if state == States.CHASING:
		if animation_player.is_playing() == false:
			animation_player.play('fly')
		nav.chase_target()
		speed = 6.5
		pass
	
	if state == States.HURTING:
		animation_player.play('hurt')
		# interrupt whever we are doing to get hurt. Maybe a 33% chance to? 
		pass

	#if state == States.ATTACKING:
		#fire()

	if state == States.DYING:
		animation_player.play('dying')
		clean_up()

	if state == States.EXPLODING:
		animation_player.pause()
		explode()
		

func explode():
	# TODO: Explode.
	animation_player.stop(true)
	await get_tree().create_timer(3.0).timeout
	queue_free()

func clean_up():
	await get_tree().create_timer(5).timeout
	if state == States.DYING:
		set_state(States.EXPLODING)

# TODO: Would be nice to have an enum of animation names somehow
func on_animation_finished(animation_name):
	if animation_name == 'hurt':
		set_state(States.CHASING)
		# TODO: if no target, add it

# TODO: Allow castle hits.
# WARNING: Do not type this as "CharacterBody3D". It must be more generic or it'll error.
func on_search_box_body_entered(body: Node3D):
	if target:
		return
	
	if body && body.is_in_group('players'):
		target = body
		set_state(States.CHASING)

func on_search_box_body_exited(body: Node3D):
	if target == body: 
		nav.timer_give_up.start()


# TODO: Use health system? 
# TODO: could call this "take_hit" or "get_hit" in a refactor
# basic_rigid_body_projectile calls "hit"
func on_hurt():
	set_state(States.HURTING)
	if !target:
		var get_player = Hub.get_player(health_system.last_damage_source) 
		if get_player:
			target = get_player
			set_state(States.CHASING)

# TODO: Ragdoll so it flops out of the sky better
func on_death():
	set_state(States.DYING)

func can_fire():
	if not target:
		return false
		
	if health_system.health == 0:
		return false
		

func fire():
	if can_fire() == false:
		return
	
	var _proj = rigid_body_projectile.instantiate()
	var _target_point = target.global_position + Vector3(0.0, 0.7, 0.0)
	var _origin_point = gun_origin.global_position
	var _direction = (_target_point - _origin_point).normalized()
	var timer = _proj.get_node_or_null('Timer')
	# Connect
	_proj.body_entered.connect(_on_player_hit.bind(_proj))
	timer.timeout.connect(func (): queue_free())
	# Add bullet
	environment_container.add_child(_proj, true)
	_proj.position = _origin_point
	_proj.set_linear_velocity( _direction * PROJECTILE_VELOCITY)
	_proj.look_at(_target_point)

# TODO: Hit more than just players, damage to buildings, etc.
func _on_player_hit(body, _projectile):
	if body.is_in_group('players'):
		body.health_system.damage(attack_value)

	_projectile.queue_free()


func give_up():
	set_state(States.SEARCHING)
