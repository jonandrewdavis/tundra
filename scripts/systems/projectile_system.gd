# TODO: Move these out of weapon manager & into a Projectile System folder
# TODO: OR - move THIS file into a restructed weapon manager area
# TODO: Refactor Projectile "Server" & Weapons Manager together

extends Node
class_name ProjectileSystem

@onready var container: Node3D = $ProjectileContainer
@onready var spawner: MultiplayerSpawner = $ProjectileSpawner

# CRITICAL: These properties should be set for the RigidBody3D 
# Not setting for each new bullet for better perf
# TODO: Can we set to the preload scene once? Maybe if we have a pool.

	#_new_bullet.gravity_scale = 0.0
	#_new_bullet.set_collision_mask(00000000_00000000_00000000_00000000)
	#_new_bullet.set_collision_layer(00000000_00000000_00000000_00000111)
	#_new_bullet.continuous_cd = true
	#_new_bullet.contact_monitor = true
	#_new_bullet.max_contacts_reported = 5

var rifle_round = preload("res://weapon_manager/Spawnable_Objects/bullet_scenes/rifle_round.tscn")

var orange_bullet = preload("res://weapon_manager/Spawnable_Objects/bullet_scenes/orange_bullet.tscn")
var pink_bullet = preload("res://weapon_manager/Spawnable_Objects/bullet_scenes/pink_bullet.tscn")
var debug_decal = preload("res://weapon_manager/Spawnable_Objects/bullet_scenes/hit_debug.tscn")
var rifle_round_decal = preload("res://weapon_manager/Spawnable_Objects/bullet_scenes/rifle_round_decal.tscn")

var bullet_list = [orange_bullet, rifle_round, pink_bullet, debug_decal, rifle_round_decal]

var display_debug_decal = true

signal hit_signal


func _ready():
	Hub.projectile_system = self

	for bullet in bullet_list:
		spawner.add_spawnable_scene(bullet.get_state().get_path())

	spawner.set_spawn_function(handle_projectile_spawn)

#var projectile_data = { 
	# projectile_name: string 
	#'origin_point': origin_point,
	#'target_point': point,
	#'projectile_velocity': Projectile_Velocity,
	#'normal': norm,
	#'damage': damage,
	#'source': source
#}

func handle_projectile_spawn(data: Variant):
	# TODO: Accept a different projectile type
	var _new_bullet: RigidBody3D 
	match data.projectile_name:
		'PinkBullet':
			_new_bullet = pink_bullet.instantiate()
		'OrangeBullet':
			_new_bullet = orange_bullet.instantiate()
		'RifleRound':
			_new_bullet = rifle_round.instantiate()
		'_':
			_new_bullet = rifle_round.instantiate()

	_new_bullet.position = data.origin_point

	_new_bullet.look_at_from_position(data.origin_point, data.target_point, Vector3.UP)	
	var _direction = (data.target_point - data.origin_point).normalized()
	_new_bullet.set_linear_velocity(_direction * data.projectile_velocity)

	if multiplayer.is_server():
		_new_bullet.body_entered.connect(_on_body_entered.bind(_new_bullet, data))
		_new_bullet.tree_entered.connect(_on_tree_entered.bind(_new_bullet))
		# TODO: Can potentially use on `body_shape_entered` or areas for crit damage.
		#_new_bullet.body_shape_entered.connect(_on_body_shape_entered.bind(_new_bullet, data))
		
	return _new_bullet

func _on_body_entered(body, _bullet, data):
	if body.is_in_group("targets") or body.is_in_group("players"):
		var heath_system: HealthSystem = body.health_system
		var damage_successful = heath_system.damage(data.damage, data.source)
		if damage_successful:
			hit_signal.emit(data.source)
	
	if data.normal:
		create_debug_decal(_bullet.get_position(), data.normal)
	
	_bullet.queue_free()
	
#func _on_body_shape_entered(_body_rid: RID, _body: Node, _body_shape_index: int, _local_shape_index: int, _bullet, data):
	#print(_body)
	
func _on_tree_entered(_bullet):
	await get_tree().create_timer(3.5).timeout
	if _bullet:
		_bullet.queue_free()
		
func create_debug_decal(pos, normal):
	if display_debug_decal:
		var rd = rifle_round_decal.instantiate()
		container.add_child(rd, true)
		rd.global_translate(pos)
		if normal.y == 1.0:
			rd.axis = 1
