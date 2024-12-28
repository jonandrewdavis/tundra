extends Node3D

signal weapon_changed
signal update_ammo
signal update_weapon_stack
signal hit_successfull
signal add_signal_to_hud
signal connect_weapon_to_hud

@export var player: CharacterBody3D

@export_category("Multiplayer Variables")
@export var weapon_stack:Array[WeaponSlot] #An Array of weapons currently in possesion by the player
@export var weapon_index = 0
var current_weapon_slot: WeaponSlot = null

@export var animation_player: AnimationPlayer
@export var melee_hitbox: ShapeCast3D
@export var max_weapons: int
@onready var bullet_point = get_node("%BulletPoint")
@onready var debug_bullet = preload("res://Player_Controller/Spawnable_Objects/hit_debug.tscn")

var next_weapon: WeaponSlot

#The List of All Available weapons in the game
var spray_profiles: Dictionary = {}
var _count = 0
var shot_tween


func _ready() -> void:
	if not player:
		push_error("Player not connected")
		return

	for weapon_model in $Weapons_Models.get_children():
		if weapon_model.has_method("hide"):
			weapon_model.hide()
		animation_player.play("RESET")
			
	if weapon_stack.is_empty():
		push_error("Weapon Stack is empty, please populate with weapons")
	else:
		animation_player.animation_finished.connect(_on_animation_finished)
		for i in weapon_stack:
			initialize(i)

		 #current starts on the first weapon in the stack
		current_weapon_slot = weapon_stack[weapon_index]
		if check_valid_weapon_slot():
			enter()
			update_weapon_stack.emit(weapon_stack)
	
func weapon_down():
	if check_valid_weapon_slot():
		weapon_index = max(weapon_index-1,0)
		exit(weapon_stack[weapon_index])

func weapon_up():
	if check_valid_weapon_slot():
		weapon_index = min(weapon_index+1,weapon_stack.size()-1)
		exit(weapon_stack[weapon_index])
		
func check_valid_weapon_slot()->bool:
	if current_weapon_slot:
		if current_weapon_slot.weapon:
			return true
		else:
			push_warning("No Weapon Resource active on the weapon controler.")
	else:
		push_warning("No Current Weapon slot active on the weapon controler.")
	return false

func initialize(_weapon_slot: WeaponSlot):
	if !_weapon_slot or !_weapon_slot.weapon:
		return
	if _weapon_slot.weapon.weapon_spray:
		spray_profiles[_weapon_slot.weapon.weapon_name] = _weapon_slot.weapon.weapon_spray.instantiate()
	connect_weapon_to_hud.emit(_weapon_slot.weapon)

func enter() -> void:
	animation_player.queue(current_weapon_slot.weapon.pick_up_animation)
	weapon_changed.emit(current_weapon_slot.weapon.weapon_name)
	update_ammo.emit([current_weapon_slot.current_ammo, current_weapon_slot.reserve_ammo])

func exit(_next_weapon: WeaponSlot) -> void:
	if _next_weapon != current_weapon_slot:
		if animation_player.get_current_animation() != current_weapon_slot.weapon.change_animation:
			animation_player.queue(current_weapon_slot.weapon.change_animation)
			next_weapon = _next_weapon

func change_weapon(weapon_slot: WeaponSlot) -> void:
	current_weapon_slot = weapon_slot
	next_weapon = null
	enter()
	
func shot_count_update() -> void:
	shot_tween = get_tree().create_tween()
	shot_tween.tween_property(self,"_count",0,1)
	
func shoot() -> void:
	if current_weapon_slot.current_ammo != 0 or not current_weapon_slot.weapon.has_ammo:
		if current_weapon_slot.weapon.incremental_reload and animation_player.current_animation == current_weapon_slot.weapon.reload_animation:
			animation_player.stop()
			
		if not animation_player.is_playing():
			animation_player.play(current_weapon_slot.weapon.shoot_animation)
			if current_weapon_slot.weapon.has_ammo:
				current_weapon_slot.current_ammo -= 1
				
			update_ammo.emit([current_weapon_slot.current_ammo, current_weapon_slot.reserve_ammo])
			
			if shot_tween:
				shot_tween.kill()
			
			var Spread = Vector2.ZERO
			
			if current_weapon_slot.weapon.weapon_spray:
				_count = _count + 1
				Spread = spray_profiles[current_weapon_slot.weapon.weapon_name].Get_Spray(_count, current_weapon_slot.weapon.magazine)
				
			load_projectile(Spread)
	else:
		reload()
		
func load_projectile(_spread):
	var _projectile:Projectile = current_weapon_slot.weapon.projectile_to_load.instantiate()
	
	_projectile._Camera = player._camera_input.camera_3D
	_projectile.position = bullet_point.global_position
	_projectile.rotation = owner.rotation
	
	bullet_point.add_child(_projectile)
	add_signal_to_hud.emit(_projectile)
	var bullet_point_origin = bullet_point.global_position
	_projectile._Set_Projectile(current_weapon_slot.weapon.damage,_spread,current_weapon_slot.weapon.fire_range, bullet_point_origin)

func reload() -> void:
	if check_valid_weapon_slot() == false:
		return

	if current_weapon_slot.current_ammo == current_weapon_slot.weapon.magazine:
		return
	elif not animation_player.is_playing():
		if current_weapon_slot.reserve_ammo != 0:
			animation_player.queue(current_weapon_slot.weapon.reload_animation)
		else:
			animation_player.queue(current_weapon_slot.weapon.out_of_ammo_animation)

func calculate_reload() -> void:
	if current_weapon_slot.current_ammo == current_weapon_slot.weapon.magazine:
		var anim_legnth = animation_player.get_current_animation_length()
		animation_player.advance(anim_legnth)
		return
		
	var Mag_Amount = current_weapon_slot.weapon.magazine
	
	if current_weapon_slot.weapon.incremental_reload:
		Mag_Amount = current_weapon_slot.current_ammo+1
		
	var Reload_Amount = min(Mag_Amount-current_weapon_slot.current_ammo,Mag_Amount,current_weapon_slot.reserve_ammo)

	current_weapon_slot.current_ammo = current_weapon_slot.current_ammo+Reload_Amount
	current_weapon_slot.reserve_ammo = current_weapon_slot.reserve_ammo-Reload_Amount
	
	update_ammo.emit([current_weapon_slot.current_ammo, current_weapon_slot.reserve_ammo])
	shot_count_update()

func melee() -> void:
	if check_valid_weapon_slot() == false:
		return
		
	var Current_Anim = animation_player.get_current_animation()
	
	if Current_Anim == current_weapon_slot.weapon.shoot_animation:
		return
		
	if Current_Anim != current_weapon_slot.weapon.melee_animation:
		animation_player.play(current_weapon_slot.weapon.melee_animation)
		if melee_hitbox.is_colliding():
			var colliders = melee_hitbox.get_collision_count()
			for c in colliders:
				var Target = melee_hitbox.get_collider(c)
				if Target.is_in_group("Target") and Target.has_method("Hit_Successful"):
					hit_successfull.emit()
					var Direction = (Target.global_transform.origin - owner.global_transform.origin).normalized()
					var Position =  melee_hitbox.get_collision_point(c)
					Target.Hit_Successful(current_weapon_slot.weapon.melee_damage, Direction, Position)
			
func drop(_slot: WeaponSlot) -> void:
	if _slot.weapon.can_be_dropped and weapon_stack.size() != 1:
		if weapon_index != -1:
			weapon_stack.pop_at(weapon_index)
			update_weapon_stack.emit(weapon_stack)

			if _slot.weapon.weapon_drop:
				var weapon_dropped = _slot.weapon.weapon_drop.instantiate()
				weapon_dropped.weapon = _slot
				weapon_dropped.set_global_transform(bullet_point.get_global_transform())
				get_tree().get_root().add_child(weapon_dropped)
				
				animation_player.play(current_weapon_slot.weapon.drop_animation)
				weapon_index  = max(weapon_index-1,0)
				exit(weapon_stack[weapon_index])
	else:
		return
		
func _on_animation_finished(anim_name):
	if anim_name == current_weapon_slot.weapon.change_animation:
		change_weapon(next_weapon)
	
	if anim_name == current_weapon_slot.weapon.reload_animation:
		if !current_weapon_slot.weapon.incremental_reload:
			calculate_reload()

func _on_pick_up_detection_body_entered(body: RigidBody3D):
	var weapon_slot = body.weapon
	for slot in weapon_stack:
		if slot.weapon == weapon_slot.weapon:
			var remaining

			remaining = add_ammo(slot, weapon_slot.current_ammo+weapon_slot.reserve_ammo)
			weapon_slot.current_ammo = min(remaining, slot.weapon.magazine)
			weapon_slot.reserve_ammo = max(remaining - weapon_slot.current_ammo,0)

			if remaining == 0:
				body.queue_free()
			return
		
	if body.TYPE == "Weapon":
		if weapon_stack.size() == max_weapons:
				return
				
		if body.Pick_Up_Ready == true:
			weapon_stack.insert(weapon_index,weapon_slot)
			update_weapon_stack.emit(weapon_stack)
			exit(weapon_slot)
			initialize(weapon_slot)
			body.queue_free()

func add_ammo(_weapon_slot: WeaponSlot, ammo: int)->int:
	var weapon = _weapon_slot.weapon
	var required = weapon.max_ammo - _weapon_slot.reserve_ammo
	var remaining = max(ammo - required,0)
	_weapon_slot.reserve_ammo += min(ammo, required)
	update_ammo.emit([current_weapon_slot.current_ammo, current_weapon_slot.reserve_ammo])
	return remaining
