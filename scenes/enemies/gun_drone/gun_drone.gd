extends CharacterBody3D

# TODO: Beehave or some other behavioral tree when this state machine gets to be too much
# TODO: Random pauses between choosing another action? "Global cool down" like
# TODO: Assure this is completely server authoratative
# TODO: Perf test navigation agent to assure it doesn't consume to much CPU or cause FPS loss

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
const FRICTION = 2
const ROTATION_SPEED: = 2.0
const PROJECTILE_VELOCITY: = 40.0

@export_category("Enemy Required Nodes")
@export var nav_agent: NavigationAgent3D
@export var animation_player: AnimationPlayer
@export var gun_origin: Marker3D
@export var health_system: HealthSystem
@export var nav: NavigationSystem
@export var search_box: Area3D

@export_category("Enemy Stats")
@export var max_speed = 5.0
@export var speed = max_speed
@export var attack_value: int = 10

var timer_attack = Timer.new()
var target = null

# This enum lists all the possible states the character can be in.
enum States { IDLE, SEARCHING, CHASING, ATTACKING, HURTING, DODGING, DYING, EXPLODING }

# This variable keeps track of the character's current state.
var state: States = States.IDLE

func _ready(): 
	# TODO: enemies group as well.
	add_to_group("targets")

	animation_player.playback_default_blend_time = 0.5
	animation_player.speed_scale = 1.5

	# This enemy only runs on the server.
	# Only visuals and some rpcs are sync'd out.
	if not multiplayer.is_server():
		# CAUTION: Trying to disable process on clients can cause MultiplayerSyncronizer issues.

		set_physics_process(false)
		set_process(false)

		# CRITICAL: Having this big search area enabled causes
		# HUGE frame rate issues for some reason
		search_box.get_node("CollisionShape3D").disabled = true

		return # Early return, no other code runs

	# Bots should fly.
	nav_agent.path_height_offset = randf_range(-4.5, -10.5)
	nav_agent.target_desired_distance = randf_range(20.0, 25.0)
	nav_agent.avoidance_enabled = true

	# TODO: Probably best to just use set_state enter/exit rather than this?
	animation_player.animation_finished.connect(on_animation_finished)
	
	# Health
	health_system.hurt.connect(on_hurt)
	health_system.death.connect(on_death)
	
	# Nav
	nav.attack_signal.connect(attack)
	nav_agent.navigation_finished.connect(on_navigation_finished)
	#nav_agent.path_changed.connect(on_path_changed)

	#add_child(timer_attack_cooldown)
	#timer_attack_cooldown.timeout.connect(attack)
	#timer_attack_cooldown.wait_time = randf_range(4.0, 7.0)
	#timer_attack_cooldown.one_shot = false
	#timer_attack_cooldown.start()

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
		new_look_at = nav.next_path_pos


	# Finally fix "Target and up vectors are colinear" by
	# doing the same checks as the source code (used C++ source!)
	# https://github.com/godotengine/godot/issues/79146
	var v_z : Vector3 = (new_look_at - position).normalized()
	# Perpendicular vector using up+front.
	var v_x : Vector3 = Vector3.UP.cross(-v_z)	
	if v_x.is_zero_approx():
		return
	
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
		nav.chase_target()	
		if animation_player.is_playing() == false:
			animation_player.play('fly')
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


func on_hurt():
	set_state(States.HURTING)
	# If there's no target, or it's attacking a castle
	if !target or target.is_in_group('player_owned'):
		var get_player = Hub.get_player(health_system.last_damage_source) 
		if get_player:
			target = get_player
			set_state(States.CHASING)

# TODO: Ragdoll so it flops out of the sky better
func on_death():
	set_state(States.DYING)

func can_attack():
	if not target:
		return false
		
	if health_system.health == 0:
		return false
		

func attack():
	if can_attack() == false:
		return
	
	var _origin_point = gun_origin.global_position
	var _target_point = target.global_position + Vector3(0.0, 0.7, 0.0)

	var projectile_data = { 
		'projectile_name': 'PinkBullet',
		'origin_point': _origin_point,
		'target_point': _target_point,
		'projectile_velocity': PROJECTILE_VELOCITY,
		'normal': null,
		'damage': attack_value,
		'source': 0,
	}
	
	Hub.projectile_system.spawner.spawn(projectile_data)

	
func on_navigation_finished():
	if state == States.CHASING:
		await get_tree().create_timer(0.4).timeout
		if nav_agent.is_navigation_finished():
			attack()
