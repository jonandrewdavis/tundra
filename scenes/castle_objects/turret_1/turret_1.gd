@tool

extends CharacterBody3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
const FRICTION = 12
const ROTATION_SPEED = 3.0

@export_category("Enemy Required Nodes")
@export var animation_player: AnimationPlayer 
@export var health_system: HealthSystem
@export var search_box: Area3D
@export var gun_origin: Marker3D
@export var marker: Marker3D

@export var peer_owner: int

var active: bool = false

@export_category("Enemy Stats")
@export var max_speed = 0.0
@export var speed = max_speed
@export var attack_value: int = 5

var timer_attack_cooldown = Timer.new()
var timer_search = Timer.new()
var target = null

enum States { IDLE, SEARCHING, TRACKING, DYING, DEAD }

var state: States = States.TRACKING

func _ready(): 
	# TODO: enemies group as well.
	add_to_group("targets")
	add_to_group("player_owned")
	
	$CollisionShape3D.disabled = true
	%connector.visible = false

	# This enemy only runs on the server.
	# Only visuals and some rpcs are sync'd out.
	if not multiplayer.is_server():
		set_physics_process(false)
		set_process(false)

		# CRITICAL: Having this big search area enabled causes
		# HUGE frame rate issues for some reason
		search_box.get_node("CollisionShape3D").disabled = true
		
		# CAUTION: Trying to disable process on clients can cause MultiplayerSyncronizer issues.
		#set_process(false)

		return # Early return, no other code runs

	health_system.ready.connect(ready_health_system)
	
	add_child(timer_attack_cooldown)
	timer_attack_cooldown.timeout.connect(shoot)
	timer_attack_cooldown.wait_time = randf_range(0.3,0.9)
	timer_attack_cooldown.one_shot = false

	add_child(timer_search)
	timer_search.timeout.connect(search_for_new_target)
	timer_search.wait_time = 2.0
	timer_search.one_shot = false
	timer_search.start()
	
	search_box.body_entered.connect(_on_body_entered_search_area)
	
	#if Engine.is_editor_hint():
		#activate(2)

func search_for_new_target():
	if target == null:
		for temp_target in $SearchBox.get_overlapping_bodies():
			if target == null:
				_on_body_entered_search_area(temp_target)
				
		if target == null:
			%gun.rotation.z = 0.0
			%connector.rotation.x = 0.0 
		
func ready_health_system():
	health_system.hurt.connect(on_hurt)
	health_system.death.connect(on_death)

func activate(peer_id):
	if active == false:
		# turn on
		$CollisionShape3D.disabled = false
		%connector.visible = true
		peer_owner = peer_id
		timer_attack_cooldown.start()
		set_state(States.TRACKING)
	else:
		$CollisionShape3D.disabled = true
		%connector.visible = false
		peer_owner = 0
		timer_attack_cooldown.stop()
		set_state(States.IDLE)

func _physics_process(delta: float) -> void:
	#if Engine.is_editor_hint():
		#move_and_look(delta)

	match state:
		States.TRACKING:
			move_and_look(delta)
	
	#velocity.y -= gravity * delta
	#move_and_slide()

const CAMERA_X_ROT_MIN := deg_to_rad(-30)
const CAMERA_X_ROT_MAX := deg_to_rad(30)
	
func move_and_look(delta):
	if target:
		var direction = Vector2(target.global_position.x, target.global_position.z).direction_to(Vector2(global_position.x, global_position.z))
		%gun.rotation.z = lerp_angle(%gun.rotation.z, atan2(direction.x, direction.y), delta)
		%connector.rotation.x = lerp_angle(%connector.rotation.x, deg_to_rad((global_position.y - target.global_position.y) * 3.0), delta)

func set_state(new_state: States) -> void:
	var _previous_state := state
	state = new_state

	############
	# You can check both the previous and the new state to determine what to do when the state changes. 
	# This checks the previous state.
	return

func on_hurt():
	pass
	
func on_death():
	pass

func _on_body_entered_search_area(body):
	if body.is_in_group('targets') and body.is_in_group('player_owned') == false:
		if not body.health_system.health == 0:
			target = body
			set_state(States.TRACKING)

func _on_body_exited(body):
	# TODO: check for id of target
	if body.is_in_group('targets') and target:
		target = null
		set_state(States.SEARCHING)

func shoot():
	if not target:
		return
	
	if peer_owner == 0:
		return
	
	if target.health_system.health == 0:
		target = null
		set_state(States.SEARCHING)
		return
	
	var _target_point = target.global_position + Vector3(0.0, 0.7, 0.0)
	await get_tree().create_timer(0.1).timeout
	
	#var _proj = rigid_body_projectile.instantiate()
	var _origin_point = gun_origin.global_position

	var projectile_data = { 
		'projectile_name': 'PinkBullet',
		'origin_point': _origin_point,
		'target_point': _target_point,
		'projectile_velocity': 80,
		'normal': null,
		'damage': attack_value,
		'source': peer_owner,
	}
	
	Hub.projectile_system.spawner.spawn(projectile_data)
