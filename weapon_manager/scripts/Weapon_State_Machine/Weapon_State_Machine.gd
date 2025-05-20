extends Node3D
class_name WeaponsManager


# TODO: This should be a true StateMachine (RewindableStateMachine?) and each WeaponResource a state within
# TODO: Enter and exit animations, updating ammo, etc.
# TODO: If you have a that weapon in posession, you can travel to it.
# TODO: This could be fully incorporated into the existing statemachine, with lots of enter, exit, display, etc.


@export var animation_player: AnimationPlayer
@export var melee_hitbox: ShapeCast3D
@export var max_weapons: int # not used
@export var player_hud: PlayerUI
@export var player: Player

@onready var bullet_point = $BulletPoint

# CRTL + Click on these to update weapon properties & stats
var blasterL: WeaponResource = preload("res://weapon_manager/scripts/Weapon_State_Machine/Weapon_Resources/blasterL.tres")
var blasterN: WeaponResource = preload("res://weapon_manager/scripts/Weapon_State_Machine/Weapon_Resources/blasterN.tres")

enum WEAPONS {blasterL, blasterN}
enum CHANGE_DIR { UP, DOWN}

signal update_weapon_signal
signal update_weapon_prev_signal

signal update_ammo_signal
signal update_ammo_prev_signal

signal reload_signal
signal melee_signal

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
	Nodash.error_missing(player, 'player')
	Nodash.error_missing(player_hud, 'player_hud')

	# Prevent clients from doing anything with their weapons.
	# This should never happen, but just in case.
	# NOTE: Weapons being invoked on clients sourced many bugs.
	if not multiplayer.is_server():
		return

	##### SERVER ONLY ######
	##### SERVER ONLY ######
	##### SERVER ONLY ######

	# ATTENTION: If you add weapons using the UI, you must set it be a local to scene resource.
	# Otherwise, scenes will share (and secretly deduct ammo from other players on the server).
	create_slot(blasterL)
	create_slot(blasterN)

	# TODO: Make sure we can handle dropping, picking up new weapons, from the overall list
	weapons_owned = [WEAPONS.blasterL, WEAPONS.blasterN]

	# This listens for the end of shooting to continue shooting Auto Fire
	# Also handles updating ammo after a reload. Must not be connected on clients.
	animation_player.animation_finished.connect(_on_animation_finished)
	
	# Await for the multiplayer syncronizer to come online before changing to our first weapon	
	await get_tree().create_timer(0.1).timeout
	if weapons_owned.size() != 0:
		animation_player.play(get_weapon(weapons_owned.front()).pick_up_animation)
		update_weapon()
		update_ammo()
		if weapons_owned.size() > 1:
			update_previous_weapon(weapons_owned[1])
			update_previous_ammo(weapons_owned[1])
	
func create_slot(weapon_to_create: WeaponResource):
	var new_slot = WeaponSlot.new()
	new_slot.weapon = weapon_to_create
	new_slot.current_ammo = weapon_to_create.magazine
	new_slot.reserve_ammo = weapon_to_create.max_ammo
	prepare_spray_pattern(weapon_to_create)
	weapons_list.append(new_slot)

func get_weapon(index: int) -> WeaponResource:
	return weapons_list[weapons_owned[index]].weapon
	
func get_slot(index: int) -> WeaponSlot:
	return weapons_list[weapons_owned[index]]

# TODO: Could use signals here to update multiple things, like HUD, etc.
func change_weapon(dir: CHANGE_DIR) -> void:
	if not multiplayer.is_server():
		push_error('Tried to change weapons on the client')
		return
		
	if busy: 
		return

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

		# NOTE: Swap text sooner to seem more responsive.
		update_previous_weapon(weapon_index)
		update_previous_ammo(weapon_index)

		update_weapon(next_weapon_index)
		update_ammo(next_weapon_index)

		await change_weapon_enter(next_weapon_index)
		weapon_index = next_weapon_index
		busy = false	

func change_weapon_enter(given_weapon_index: int):
	animation_player.play(get_weapon(given_weapon_index).pick_up_animation)
	await get_tree().create_timer(animation_player.current_animation_length + .2).timeout

func change_weapon_leave(given_weapon_index: int):
	animation_player.play(get_weapon(given_weapon_index).change_animation)
	await get_tree().create_timer(animation_player.current_animation_length + .2).timeout

# TODO: Optional refactor: Use network weapon from Netfox to shoot client side & rollback.
func can_fire():
	if busy or get_slot(weapon_index) == null or get_weapon(weapon_index) == null:
		return false
		
	if player._player_input.run_input:
		return false
		
	return true

##############################################################
# NOTE: Below here are functions adapated from the template
##############################################################

# TODO: Make preparing and retrieving sprays not stored by name?
func prepare_spray_pattern(weapon_to_prepare: WeaponResource):
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
	#_projectile.hit_signal.connect(hit_signal_stub)
	
	# NOTE: added true
	bullet_point.add_child(_projectile, true)
	var bullet_point_origin = bullet_point.global_position
	_projectile.source = int(player.name)
	_projectile._Set_Projectile(current_weapon.damage, spread, current_weapon.fire_range, bullet_point_origin)

# Calls directly to the parent HUD.	
# When using signals, tended to emit on other players
#func hit_signal_stub():
	#player_hud._on_weapons_manager_hit_signal()

func shoot():
	# TODO: Use the rollback syncronizer and "is_fresh".
	# Note: Usually not possible with our RPC rules, but warn about the client using this.
	if not multiplayer.is_server():
		push_warning("A client tried to call locally to shoot: ", multiplayer.get_unique_id())
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
		
		# TODO: Could change animation speed scale to reward non-zoom shots, or not.
		if current_weapon.weapon_spray and not player._player_input.aim_input:
			count = count + 1
			# if player_input.aim == false:
			Spread = spray_profiles[current_weapon.weapon_name].Get_Spray(count, current_weapon.magazine)

		load_projectile(Spread)
		await get_tree().process_frame
		# play sound
		update_ammo(weapon_index, true)


func _on_animation_finished(animation_finished_name):
	var current_weapon = get_weapon(weapon_index)

	match animation_finished_name:
		current_weapon.shoot_animation: 
			if get_slot(weapon_index).current_ammo == 0: 
				reload()
			else:
				_auto_fire_shoot()
			
		current_weapon.reload_animation:
			if !current_weapon.incremental_reload:
				calculate_reload()
				_auto_fire_shoot()

func _auto_fire_shoot():
	if get_weapon(weapon_index).auto_fire && player_input.shoot_input:
		shoot()

func reload() -> void:
	if not multiplayer.is_server():
		push_warning('Tried to reload on the client: ', multiplayer.get_unique_id())
		return

	# Added
	var current_weapon_slot = get_slot(weapon_index)
	
	# TODO: Change.
	# Not changed
	if current_weapon_slot.current_ammo == current_weapon_slot.weapon.magazine:
		return
	elif not animation_player.is_playing():
		reload_signal.emit()
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
	update_ammo()

	# Note: Not 100% sure about this, but it's for resetting spray patterns, I believe:
	count = 0

func melee() -> void:
	var current_weapon = get_weapon(weapon_index)
	var current_animation = animation_player.get_current_animation()
	
	if current_animation == current_weapon.shoot_animation or current_animation == current_weapon.melee_animation:
		return
		
	if current_animation != current_weapon.melee_animation:
		animation_player.play(current_weapon.melee_animation)
		melee_signal.emit()
		await get_tree().create_timer(0.1).timeout
		if melee_hitbox.is_colliding():
			var colliders = melee_hitbox.get_collision_count()
			for col in colliders:
				var body: Node3D = melee_hitbox.get_collider(col)
				if not body:
					return
				if body.is_in_group('targets') or body.is_in_group('players'):
					var heath_system: HealthSystem = body.health_system
					var damage_successful = heath_system.damage(current_weapon.melee_damage, int(player.name))
					if damage_successful:
						Hub.projectile_system.hit_signal.emit(int(player.name))
	
				# WARNING: DEPRECATED MELEE CODE. REMOVE.
				#if target.is_in_group("targets") and target.has_method("hit"):
					#player_hud.hit_signal.emit()
					#var dir = (target.global_transform.origin - owner.global_transform.origin).normalized()
					#var pos =  melee_hitbox.get_collision_point(col)
					#target.hit(current_weapon.melee_damage, dir, pos)

######## HUD Helpers ########
######## HUD Helpers ########
######## HUD Helpers ########

# These emit on the server in the player HUD
# The server's player HUD then RPCs (rpc_id) the data down the client to display
func update_weapon(given_index: int = weapon_index):
	update_weapon_signal.emit(get_slot(given_index).weapon.weapon_name)

func update_ammo(given_index: int = weapon_index, is_shooting: bool = false):
	var weapon = get_slot(given_index)
	update_ammo_signal.emit(weapon.current_ammo, weapon.reserve_ammo, is_shooting)

func update_previous_weapon(given_index: int):
	update_weapon_prev_signal.emit(get_slot(given_index).weapon.weapon_name)

func update_previous_ammo(given_index: int):
	var weapon = get_slot(given_index)
	update_ammo_prev_signal.emit(weapon.current_ammo, weapon.reserve_ammo)
