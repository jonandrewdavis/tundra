# TODO: Beehave or some other behavioral tree when this state machine gets to be too much
# TODO: Random pauses between choosing another action? "Global cool down" like
# TODO: Assure this is completely server authoratative
# TODO: Perf test navigation agent to assure it doesn't consume to much CPU or cause FPS loss

extends CharacterBody3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
const FRICTION = 12
const ROTATION_SPEED = 3.0

@export_category("Enemy Required Nodes")
@export var animation_player: AnimationPlayer 
@export var health_system: HealthSystem
@export var nav: NavigationSystem
@export var nav_agent: NavigationAgent3D
@export var search_box: Area3D
@export var attack_box: Area3D

# TODO: Weak points and eyeline
# TODO: Give up chase 
#@export var hit_box: Area3D
#@export var eyeline: Area3D 

@export_category("Enemy Stats")
@export var max_speed = 5.0
@export var speed = max_speed
@export var attack_value: int = 30

var timer_attack_cooldown = Timer.new()

var target = null

# This enum lists all the possible states the character can be in.
enum States { IDLE, SEARCHING, CHASING, ATTACKING, HURTING, DODGING, DYING, DECAYING }

# This variable keeps track of the character's current state.
var state: States = States.IDLE

func _ready(): 
	# TODO: enemies group as well.
	add_to_group("targets")
	
	# TODO: FIGURE OUT CONDITIONAL set_collision_layer_value (mask?) PASS THROUGH FOR PLAYERS / OTHERS
	set_collision_layer_value(1, false) 
	set_collision_layer_value(2, true)
	set_collision_mask_value(1, false) 
	set_collision_mask_value(2, true)

	animation_player.playback_default_blend_time = 0.5
	animation_player.speed_scale = 1.5

	# This enemy only runs on the server.
	# Only visuals and some rpcs are sync'd out.
	if not multiplayer.is_server():
		set_physics_process(false)
		set_process(false)

		# CRITICAL: Having this big search area enabled causes
		# HUGE frame rate issues for some reason
		search_box.get_node("CollisionShape3D").disabled = true
		attack_box.get_node("CollisionShape3D").disabled = true
		
		# CAUTION: Trying to disable process on clients can cause MultiplayerSyncronizer issues.
		#set_process(false)

		return # Early return, no other code runs

	nav_agent.target_desired_distance = randf_range(6.5, 8.0)
	nav_agent.avoidance_enabled = true

	# Connect & create
	attack_box.body_entered.connect(on_attack_box_entered)
	
	
	# TODO: Probably best to just use set_state enter/exit rather than this?
	animation_player.animation_finished.connect(on_animation_finished)
	
	# Health
	health_system.hurt.connect(on_hurt)
	health_system.death.connect(on_death)
	
	# Nav
	nav.give_up_signal.connect(give_up)
	nav.attack_signal.connect(attack)
	nav_agent.navigation_finished.connect(on_navigation_finished)
	nav_agent.path_changed.connect(on_path_changed)


	add_child(timer_attack_cooldown)
	timer_attack_cooldown.timeout.connect(attack)
	timer_attack_cooldown.wait_time = randf_range(4.0, 7.0)
	timer_attack_cooldown.one_shot = false
	timer_attack_cooldown.start()

	await get_tree().create_timer(0.2).timeout
	set_state(States.SEARCHING)

func _physics_process(delta: float) -> void:
	match state:
		States.SEARCHING:
			move_and_look(delta)
		States.CHASING, States.HURTING:
			move_and_look(delta)
		States.ATTACKING:
			move_and_attack(delta)
		States.DYING:
			velocity = Vector3.ZERO
		States.DECAYING:
			velocity = Vector3.ZERO
	
	velocity.y -= gravity * delta

	move_and_slide()
	
# TODO: ADD LOOK
func move_and_attack(_delta):
	if position.distance_to(attack_position) > 1.0:
		velocity = (attack_position - global_transform.origin).normalized() * speed * 2
	elif position.distance_to(attack_position) > 12.0: 
		set_state(States.CHASING)
		nav.chase_target()
	else:
		set_state(States.CHASING)
		nav.chase_target()

func move_and_look(delta):
	var new_look_at
	if nav_agent.is_navigation_finished() == false:
		velocity = (nav.next_path_pos - global_transform.origin).normalized() * speed
	else:
		velocity = velocity.move_toward(Vector3.ZERO, FRICTION * delta)
		velocity.y -= gravity * delta

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

	############
	# You can check both the previous and the new state to determine what to do when the state changes. 
	# This checks the previous state.

	# Never leave Decaying.
	if previous_state == States.DECAYING: 
		return

	if previous_state == States.ATTACKING && new_state == States.HURTING:
		animation_player.play('dog_animations_1/hurt')
		return
		
	if previous_state == States.ATTACKING && animation_player.current_animation == 'dog_animations_1/jump': 
		return

	#############
	# Here, I check the new state.
	if state == States.SEARCHING:
		target = null
		animation_player.play('dog_animations_1/walk')
		speed = 3.0
		nav.pick_patrol_destination()
		pass

	if state == States.CHASING:
		animation_player.play('dog_animations_1/walk')
		nav.chase_target()
		speed = 6.5
		pass
		
	if state == States.ATTACKING:
		attack_box.set_deferred('monitoring', true)
	else:
		attack_box.set_deferred('monitoring', false)
	
	if state == States.HURTING:
		if health_system.health == 0:
			return
		animation_player.play('dog_animations_1/hurt')
		# TODO: interrupt whever we are doing to get hurt. Maybe a 33% chance to? 
		if !target or target.is_in_group('player_owned'):
			var get_player = Hub.get_player(health_system.last_damage_source) 
			if get_player:
				target = get_player
				set_state(States.CHASING)

	if state == States.DYING:
		# Helps prevent monitoring issues
		nav.timer_chase_target.stop()
		nav.timer_navigate.stop()
		nav.timer_give_up.stop()
		animation_player.play('dog_animations_1/dying')
		# Decay triggered by animation

	if state == States.DECAYING:
		animation_player.play('dog_animations_1/decay')
		decay()
		pass

func decay():
	await get_tree().create_timer(10.0).timeout
	animation_player.stop()
	set_process(false)
	await get_tree().process_frame
	queue_free()

# TODO: Would be nice to have an enum of animation names somehow
func on_animation_finished(animation_name):
	if animation_name == 'dog_animations_1/hurt':
		if target:
			set_state(States.CHASING)
			animation_player.play('dog_animations_1/idle')
	
	if animation_name == 'dog_animations_1/dying':
		set_state(States.DECAYING)
		
	if animation_name == 'dog_animations_1/jump':
		if health_system.health == 0:
			set_state(States.DYING)

func on_hurt():
	set_state(States.HURTING)
	
	
func on_death():
	set_state(States.DYING)

func can_attack() -> bool:
	if not target:
		return false
		
	if health_system.health == 0:
		return false
		
	if state in [States.ATTACKING, States.DYING, States.DECAYING]:
		return false


	return true


var attack_position

func attack():
	if can_attack() == false:
		return

	if state == States.CHASING or state == States.HURTING:
		await get_tree().create_timer(0.7).timeout
		if nav_agent.is_navigation_finished():
			if target and global_position.distance_to(target.transform.origin) < 9.0:
				attack_position = target.transform.origin
				set_state(States.ATTACKING)
				attack_position = attack_position + Vector3(0.0, 0.5, 0.0)
				animation_player.play('dog_animations_1/jump')

func give_up():
	set_state(States.SEARCHING)

# TODO: These are bad. ...
func on_navigation_finished():
	animation_player.play('dog_animations_1/idle')

func on_path_changed():
	if state == States.ATTACKING: 
		return

	if animation_player.current_animation == 'dog_animations_1/idle':
		animation_player.play('dog_animations_1/walk')
		
	if animation_player.current_animation == 'dog_animations_1/hurt':
		animation_player.play('dog_animations_1/walk')

func on_attack_box_entered(body):
	if body.is_in_group('players'):
		var damage_successful = body.health_system.damage(attack_value, 0)
		if damage_successful && attack_box:
			attack_box.set_deferred('monitoring', false)
