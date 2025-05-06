# TODO: This entire part of the code-base needs a complete refactor.
# TODO: This entire part of the code-base needs a complete refactor.
# TODO: This entire part of the code-base needs a complete refactor.

extends Node3D
class_name Projectile

## Can Be Either A Hit Scan or Rigid Body Projectile. If Rigid body is select a Rigid body must be provided.
@export_enum ("Hitscan","Rigidbody_Projectile","over_ride") var Projectile_Type: String = "Hitscan"

# TODO: Better decals (flat).
@export var display_decal: bool = true

@export var projectile_velocity: int = 20
@export var rigid_body_projectile: PackedScene
@export var pass_through: bool = false

@onready var projectile_spawner = get_tree().get_first_node_in_group("ProjectileSpawner")

var debug_bullet
var source: int = 1

var damage: int = 0
var Projectiles_Spawned = []
var hit_objects: Array = []

var _Camera: Camera3D

func _ready() -> void:
	pass

func _Set_Projectile(_damage: int = 0, _spread:Vector2 = Vector2.ZERO, _Range: int = 1000, origin_point: Vector3 = Vector3.ZERO):
	damage = _damage
	Fire_Projectile(_spread, _Range, origin_point)

func Fire_Projectile(_spread: Vector2, _range: int, origin_point: Vector3):
	var Camera_Collision = Camera_Ray_Cast(_spread,_range)
	
	match Projectile_Type:
		"Hitscan":
			Hit_Scan_Collision(Camera_Collision, damage, origin_point)
		"Rigidbody_Projectile":
			Launch_Rigid_Body_Projectile(Camera_Collision, rigid_body_projectile, origin_point)
		"over_ride":
			_over_ride_collision(Camera_Collision, damage)

func _over_ride_collision(_camera_collision:Array, _damage: float) -> void:
	pass

func Camera_Ray_Cast(_spread: Vector2 = Vector2.ZERO, _range: float = 1000):
	var Ray_Origin = _Camera.project_ray_origin(Hub.viewport/2)
	var Ray_End = (Ray_Origin + _Camera.project_ray_normal((Hub.viewport/2)+Vector2i(_spread)) * _range)
	var New_Intersection:PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(Ray_Origin,Ray_End)
	New_Intersection.set_collision_mask(0b11101111) # 15? 
	New_Intersection.set_hit_from_inside(false) # In Jolt this is set to true by defualt
	
	# 0: The colliding object
	# 1: The colliding object's ID.
	# 2: The object's surface normal at the intersection point or Vector3.ZERO
	# 3: position: The intersection point.
	var Intersection = get_world_3d().direct_space_state.intersect_ray(New_Intersection)
	
	if Intersection.is_empty():
		return [null, Ray_End, null]	
	
	return [Intersection.collider, Intersection.position, Intersection.normal]


func Hit_Scan_Collision(Collision: Array,_damage: float, origin_point: Vector3):
	var Point = Collision[1]
	if Collision[0]:
		
		Hub.projectile_system.create_debug_decal(Point, Collision[2])
		
		if Collision[0].is_in_group("targets"):
			var Bullet = get_world_3d().direct_space_state

			var Bullet_Direction = (Point - origin_point).normalized()
			var New_Intersection = PhysicsRayQueryParameters3D.create(origin_point,Point+Bullet_Direction*2)
			New_Intersection.set_collision_mask(0b11101111) 
			New_Intersection.set_hit_from_inside(false)
			#New_Intersection.set_exclude(hit_objects)
			var Bullet_Collision = Bullet.intersect_ray(New_Intersection)
			if Bullet_Collision:
				Hit_Scan_damage(Bullet_Collision.collider, Bullet_Direction,Bullet_Collision.position,_damage)
				if pass_through and check_pass_through(Bullet_Collision.collider, Bullet_Collision.rid):
					var pass_through_collision : Array = [Bullet_Collision.collider, Bullet_Collision.position, Bullet_Collision.normal]
					@warning_ignore("integer_division")
					var pass_through_damage: float = damage/2
					Hit_Scan_Collision(pass_through_collision,pass_through_damage,Bullet_Collision.position)
					return

			queue_free()

func check_pass_through(_collider: Node3D, _rid: RID)-> bool:
	#var valid_pass_though: bool = false
	#if collider.is_in_group("targets"):
		#hit_objects.append(rid)
		#valid_pass_though = true
	#return valid_pass_though
	return true


# TODO: PackedBytes or Array to save data over the wire.
func Launch_Rigid_Body_Projectile(collision_data, projectile: PackedScene, origin_point):
	var projectile_data = { 
		'projectile_name': projectile.get_state().get_node_name(0),
		'origin_point': origin_point,
		'target_point': collision_data[1],
		'projectile_velocity': projectile_velocity,
		'normal': collision_data[2],
		'damage': damage,
		'source': source
	}
	
	Hub.projectile_system.spawner.spawn(projectile_data)

func Hit_Scan_damage(collision, _direction, _position, _damage):
	if collision.is_in_group("targets") or collision.is_in_group("players"):
		var heath_system: HealthSystem = collision.health_system
		var damage_successful = heath_system.damage(damage, source)
		if damage_successful:
			Hub.projectile_system.hit_signal.emit(source)
