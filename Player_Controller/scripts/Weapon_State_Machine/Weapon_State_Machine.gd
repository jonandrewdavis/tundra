extends Node3D
class_name WeaponsManager

@export var animation_player: AnimationPlayer
@export var melee_hitbox: ShapeCast3D
@export var max_weapons: int

@onready var bullet_point = $BulletPoint
@onready var debug_bullet = preload("res://Player_Controller/Spawnable_Objects/hit_debug.tscn")

signal weapon_changed

enum WEAPONS {blasterL, blasterN}
enum CHANGE_DIR { UP, DOWN}

var blasterL: WeaponResource = preload("res://Player_Controller/scripts/Weapon_State_Machine/Weapon_Resources/blasterL.tres")
var blasterN: WeaponResource = preload("res://Player_Controller/scripts/Weapon_State_Machine/Weapon_Resources/blasterN.tres")

# TODO: Load the list programmatically as well.
# NOTE: weapons_list: All the posible weapon resources & starting ammo, as WeaponSlot
# NOTE: weapons_owned: (MultiplayerSync) A list of enums, 0 - 5
# NOTE: weapon_index: (MultiplayerSync) indexes into -> weapons_list -> weapons_owned to retrieve the WeaponResource
@export var weapons_list: Array[WeaponSlot]
@export var weapons_owned: Array[WEAPONS] 
@export var weapon_index: int = 0

var _count = 0
var spray_profiles: Dictionary = {}

var player_camera_3D: Camera3D
var busy = false

func _ready() -> void:
	for weapon_slot in weapons_list:
		prepare_spray_patterns(weapon_slot.weapon)

	weapons_owned = [WEAPONS.blasterL, WEAPONS.blasterN]



func get_weapon(index: int) -> WeaponResource:
	return weapons_list[weapons_owned[index]].weapon
	
func get_slot(index: int) -> WeaponSlot:
	return weapons_list[weapons_owned[index]]

# TODO: Could use signals here to update multiple things, like HUD, etc.
# TODO: Decide if we want to emit the current "WeaponSlot" (might be helpful for HUD)
# TODO: Should reject if an action is currently running
func change_weapon(dir: CHANGE_DIR) -> void:
	var next_weapon_index
	if dir == CHANGE_DIR.UP:
		next_weapon_index = weapon_index - 1
	elif dir == CHANGE_DIR.DOWN:
		next_weapon_index = weapon_index + 1
		
	if next_weapon_index < 0 or next_weapon_index > weapons_owned.size() - 1:
		return
	
	if not busy && next_weapon_index != weapon_index:
		busy = true
		animation_player.play(get_weapon(weapon_index).change_animation)
		await get_tree().create_timer(animation_player.current_animation_length + .05).timeout
		
		var new_weapon = get_weapon(next_weapon_index)
		animation_player.play(new_weapon.pick_up_animation)
		await get_tree().create_timer(animation_player.current_animation_length + .05).timeout

		weapon_index = next_weapon_index
		weapon_changed.emit()
		busy = false

# TODO: networked weapon from netfox, ammo checks
func can_fire():
	return true



##############################################################
# NOTE: Below here are functions adapated from the template
##############################################################

func prepare_spray_patterns(weapon: WeaponResource):
	var _weapon_to_prepare = weapon
	if _weapon_to_prepare.weapon_spray:
		spray_profiles[_weapon_to_prepare.weapon_name] = _weapon_to_prepare.weapon_spray.instantiate()

func load_projectile(_spread):
	var _current_weapon = get_weapon(weapon_index)
	var _projectile: Projectile = _current_weapon.projectile_to_load.instantiate()
	
	_projectile._Camera = player_camera_3D
	_projectile.position = bullet_point.global_position
	_projectile.rotation = owner.rotation
	
	bullet_point.add_child(_projectile)
	#add_signal_to_hud.emit(_projectile)
	var bullet_point_origin = bullet_point.global_position
	_projectile._Set_Projectile(_current_weapon.damage,_spread,_current_weapon.fire_range, bullet_point_origin)

func shoot():
	if can_fire() == false:
		return
	
	if not animation_player.is_playing():
		var _current_weapon = get_weapon(weapon_index)
		var _current_slot = get_slot(weapon_index)
		
		animation_player.play(_current_weapon.shoot_animation)
		if _current_weapon.has_ammo:
			_current_slot.current_ammo -= 1
		
		var Spread = Vector2.ZERO
		
		if _current_weapon.weapon_spray:
			_count = _count + 1
			Spread = spray_profiles[_current_weapon.weapon_name].Get_Spray(_count, _current_weapon.magazine)
			
		load_projectile(Spread)
