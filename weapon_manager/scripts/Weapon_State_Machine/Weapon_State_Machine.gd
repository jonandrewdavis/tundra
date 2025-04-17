extends Node3D
class_name WeaponsManager

# TODO: This should be a true StateMachine (RewindableStateMachine?) and each WeaponResource a state within
# TODO: Enter and exit animations, updating ammo, etc.
# TODO: If you have a that weapon in posession, you can travel to it.

@export var animation_player: AnimationPlayer
@export var melee_hitbox: ShapeCast3D
@export var max_weapons: int # not used
@export var player_hud: CanvasLayer
@export var player: CharacterBody3D

@onready var bullet_point = $BulletPoint
@onready var debug_bullet = preload("res://weapon_manager/Spawnable_Objects/hit_debug.tscn")

var blasterL: WeaponResource = preload("res://weapon_manager/scripts/Weapon_State_Machine/Weapon_Resources/blasterL.tres")
var blasterN: WeaponResource = preload("res://weapon_manager/scripts/Weapon_State_Machine/Weapon_Resources/blasterN.tres")

enum WEAPONS {blasterL, blasterN}
enum CHANGE_DIR { UP, DOWN}

# TODO: Load the list programmatically as well.
# NOTE: weapons_list: All the posible weapon resources & starting ammo, as WeaponSlot
# NOTE: weapons_owned: (MultiplayerSync) A list of enums, 0 - 5
# NOTE: weapon_index: (MultiplayerSync) indexes into -> weapons_list -> weapons_owned to retrieve the WeaponResource
@export var weapons_list: Array[WeaponSlot]
@export var weapons_owned: Array[WEAPONS] 
@export var weapon_index: int = 0

var count = 0
var spray_profiles: Dictionary = {}

var player_input: PlayerInput
var player_camera_3D: Camera3D
var busy = false

func _ready() -> void:
	Lodash.error(player, 'player')
	Lodash.error(player_hud, 'player_hud')

	for weapon_slot in weapons_list:
		prepare_spray_patterns(weapon_slot.weapon)
	
	# Prevent clients from doing anything with their 
	# This should never happen, but just in case
	# TODO: This line prevents preparing weapon spray
	if not multiplayer.is_server():
		return

	##### SERVER ONLY ######
	weapons_owned = [WEAPONS.blasterL, WEAPONS.blasterN]

	# This listens for the end of shooting to continue shooting Auto Fire
	# Also handles updating ammo after a reload. Must not be connected on clients.
	animation_player.animation_finished.connect(_on_animation_finished)
	
	# Await for the multiplayer syncronizer to come online before changing to our first weapon	
	await get_tree().create_timer(0.1).timeout
	animation_player.play(get_weapon(weapons_owned[0]).pick_up_animation)

func get_weapon(index: int) -> WeaponResource:
	return weapons_list[weapons_owned[index]].weapon
	
func get_slot(index: int) -> WeaponSlot:
	return weapons_list[weapons_owned[index]]

# TODO: Could use signals here to update multiple things, like HUD, etc.
# TODO: Decide if we want to emit the current "WeaponSlot" (might be helpful for HUD)
func change_weapon(dir: CHANGE_DIR) -> void:
	if not multiplayer.is_server():
		push_error('Tried to change weapons on the client')
		return
		
	if busy: 
		return

	print('CHANGE WEAPON', dir)
	var next_weapon_index
	if dir == CHANGE_DIR.UP:
		next_weapon_index = weapon_index - 1
	elif dir == CHANGE_DIR.DOWN:
		next_weapon_index = weapon_index + 1
		
	if next_weapon_index < 0 or next_weapon_index > weapons_owned.size() - 1:
		return
	
	if not busy && next_weapon_index != weapon_index:
		busy = true
		await change_weapon_leave(weapon_index)
		await change_weapon_enter(next_weapon_index)
		weapon_index = next_weapon_index
		player_hud.weapon_changed.emit() # TODO: HUD update
		var get_latest_slot = get_slot(weapon_index)
		player_hud.update_ammo.emit([get_latest_slot.current_ammo, get_latest_slot.reserve_ammo])
		busy = false	
		
	print('NEW WEAPON IS', get_weapon(weapon_index).pick_up_animation)


func change_weapon_enter(given_weapon_index: int):
	animation_player.play(get_weapon(given_weapon_index).pick_up_animation)
	await get_tree().create_timer(animation_player.current_animation_length + .2).timeout

func change_weapon_leave(given_weapon_index: int):
	animation_player.play(get_weapon(given_weapon_index).change_animation)
	await get_tree().create_timer(animation_player.current_animation_length + .2).timeout

# TODO: networked weapon from netfox, ammo checks, more things
# TODO: This runs for everyone. A client can reload another client's gun.
func can_fire():
	if get_slot(weapon_index) == null or get_weapon(weapon_index) == null:
		return false

	return true

##############################################################
# NOTE: Below here are functions adapated from the template
##############################################################

# TODO: Make preparing and retrieving sprays not stored by name?
func prepare_spray_patterns(weapon_to_prepare: WeaponResource):
	if weapon_to_prepare.weapon_spray:
		spray_profiles[weapon_to_prepare.weapon_name] = weapon_to_prepare.weapon_spray.instantiate()

func load_projectile(spread):
	var current_weapon = get_weapon(weapon_index)
	var _projectile: Projectile = current_weapon.projectile_to_load.instantiate()
	
	_projectile._Camera = player_camera_3D
	_projectile.position = bullet_point.global_position
	_projectile.rotation = owner.rotation
	############
	# TODO: Document how I connected the signals in code.
	############
	_projectile.hit_signal.connect(hit_signal_stub)
	
	# NOTE: added true
	bullet_point.add_child(_projectile, true)
	var bullet_point_origin = bullet_point.global_position
	_projectile.debug_bullet = debug_bullet
	_projectile._Set_Projectile(current_weapon.damage, spread, current_weapon.fire_range, bullet_point_origin)

# Calls directly to the parent HUD.	
# When using signals, tended to emit on other players
func hit_signal_stub():
	player_hud._on_weapons_manager_hit_signal()

func shoot():
	# TODO: Use the rollback syncronizer and "is_fresh".
	# Note: Usually not possible with our RPC rules, but warn about the client using this.
	if not multiplayer.is_server():
		push_warning("A client tried to call locally to shoot")
		return
	
	if can_fire() == false:
		return

	if get_slot(weapon_index).current_ammo == 0: 
		reload()
		return 
	
	if not animation_player.is_playing():
		var current_weapon = get_weapon(weapon_index)
		var current_slot = get_slot(weapon_index)
		
		animation_player.play(current_weapon.shoot_animation)
		if current_weapon.has_ammo:
			current_slot.current_ammo -= 1
		
		var Spread = Vector2.ZERO
		
		# TODO: weapon_name is required for spray... remove this
		# to allow us to rename weapons from "blasterL', eww...
		if current_weapon.weapon_spray:
			count = count + 1
			Spread = spray_profiles[current_weapon.weapon_name].Get_Spray(count, current_weapon.magazine)

		load_projectile(Spread)

func _on_animation_finished(animation_finished_name):
	var current_weapon = get_weapon(weapon_index)

	match animation_finished_name:
		current_weapon.shoot_animation: 
			_auto_fire_shoot()
		current_weapon.reload_animation:
			if !current_weapon.incremental_reload:
				calculate_reload()
				_auto_fire_shoot()

func _auto_fire_shoot():
	if get_weapon(weapon_index).auto_fire && player_input.shoot_input:
		shoot()

func reload() -> void:
	# Added
	var current_weapon_slot = get_slot(weapon_index)
	
	# TODO: Change.
	# Not changed
	if current_weapon_slot.current_ammo == current_weapon_slot.weapon.magazine:
		return
	elif not animation_player.is_playing():
		if current_weapon_slot.reserve_ammo != 0:
			animation_player.queue(current_weapon_slot.weapon.reload_animation)
		else:
			animation_player.queue(current_weapon_slot.weapon.out_of_ammo_animation)
	
func calculate_reload() -> void:
	var current_weapon_slot = get_slot(weapon_index)

	if current_weapon_slot.current_ammo == current_weapon_slot.weapon.magazine:
		var anim_legnth = animation_player.get_current_animation_length()
		animation_player.advance(anim_legnth)
		return
		
	var mag_amount = current_weapon_slot.weapon.magazine
	
	if current_weapon_slot.weapon.incremental_reload:
		mag_amount = current_weapon_slot.current_ammo + 1
		
	var reload_amount = min(mag_amount - current_weapon_slot.current_ammo, mag_amount, current_weapon_slot.reserve_ammo)

	current_weapon_slot.current_ammo = current_weapon_slot.current_ammo + reload_amount
	current_weapon_slot.reserve_ammo = current_weapon_slot.reserve_ammo - reload_amount
	
	player_hud.update_ammo([current_weapon_slot.current_ammo, current_weapon_slot.reserve_ammo])

	# Note: Not 100% sure about this, but it's for resetting spray patterns, I believe:
	count = 0

func melee() -> void:
	var current_weapon = get_weapon(weapon_index)
	var current_animation = animation_player.get_current_animation()
	
	if current_animation == current_weapon.shoot_animation:
		return
		
	if current_animation != current_weapon.melee_animation:
		animation_player.play(current_weapon.melee_animation)
		if melee_hitbox.is_colliding():
			var colliders = melee_hitbox.get_collisioncount()
			for col in colliders:
				var target = melee_hitbox.get_collider(col)
				if target.is_in_group("targets") and target.has_method("hit"):
					player_hud.hit_signal.emit()
					var dir = (target.global_transform.origin - owner.global_transform.origin).normalized()
					var pos =  melee_hitbox.get_collision_point(col)
					target.hit(current_weapon.melee_damage, dir, pos)
