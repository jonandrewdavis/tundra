extends Node

@onready var projectile_container: Node3D = $ProjectileContainer
@onready var projectile_spawner: MultiplayerSpawner = $ProjectileSpawner

# TODO: Move these out of weapon manager & into a Projectile System folder
# TODO: OR - move THIS file into a restructed weapon manager area
var bullet = preload("res://weapon_manager/Spawnable_Objects/bullet.tscn")
var debug_decal = preload("res://weapon_manager/Spawnable_Objects/hit_debug.tscn")

var display_debug_decal = true

signal hit_signal

func _ready():
	Hub.projectile_spawner = $ProjectileSpawner
	$ProjectileSpawner.set_spawn_function(handle_projectile_spawn)

#var projectile_data = { 
	#'origin_point': origin_point,
	#'target_point': point,
	#'projectile_velocity': Projectile_Velocity,
	#'normal': norm,
	#'damage': damage,
	#'source': source
#}
func handle_projectile_spawn(data: Variant):
	var _new_bullet = bullet.instantiate()
	_new_bullet.position = data.origin_point
	_new_bullet.look_at_from_position(data.origin_point, data.target_point, Vector3.UP)
	
	var _direction = (data.target_point - data.origin_point).normalized()
	_new_bullet.set_linear_velocity(_direction * data.projectile_velocity)

	if multiplayer.is_server():
		_new_bullet.body_entered.connect(_on_body_entered.bind(_new_bullet, data))
		_new_bullet.tree_entered.connect(_on_tree_entered.bind(_new_bullet))
		
	return _new_bullet

# TODO: Can potentially use on `body_shape_entered` or areas for crit damage.
func _on_body_entered(body, _bullet, data):
	if body.is_in_group("targets") or body.is_in_group("players"):
		var heath_system: HealthSystem = body.health_system
		var damage_successful = heath_system.damage(data.damage, data.source)
		if damage_successful:
			hit_signal.emit()
	
	if data.normal:
		create_debug_decal(_bullet.get_position(), data.normal)
	
	_bullet.queue_free()
	
func _on_tree_entered(_bullet):
	await get_tree().create_timer(4.0).timeout
	if _bullet:
		_bullet.queue_free()
		
func create_debug_decal(pos, normal):
	if display_debug_decal:
		var rd = debug_decal.instantiate()
		projectile_container.add_child(rd, true)
		rd.global_translate(pos)
		if normal.y == 1.0:
			rd.axis = 1
