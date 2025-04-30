extends CanvasLayer
class_name PlayerUI

@export var weapons_manager: WeaponsManager
@export var health_bar: ProgressBar
@export var health_label: Label
@export var sync: MultiplayerSynchronizer

# TODO: When UI items move around, they're often reparented...
# Use the export & select method above. It keeps them current.
# Alternatively, use "access as unique name", which is kinda the same effect.
@onready var hit_sight = $HitSight
@onready var snow_shader = $Shaders/SnowShader

var local_max_health: int = 100

# TODO: Is this the best place for these?
# TODO: Weapon stack, current weapon, current weapon image


var hit_sight_timer = Timer.new()

func _ready():
	if not multiplayer.is_server():
		DebugMenu.style = DebugMenu.Style.VISIBLE_DETAILED
		

	Nodash.error_missing(weapons_manager, 'Weapons Manager')

	# WITH: 130 kib
	# 
	#Nodash.sync_property(sync, hit_sight, ['visible'])
	Nodash.sync_property(sync, %CurrentAmmo, ['text'])
	#Nodash.sync_property(sync, %CurrentWeaponLabel, ['text'])
	#Nodash.sync_property(sync, %BackupWeaponLabel, ['text'])
	#Nodash.sync_property(sync, %BackupAmmo, ['text'])

	# If the parent is the player that owns the UI 
	var peer_uid: int = multiplayer.get_unique_id()	
	if str(peer_uid) != get_parent().name:
		hide()
		# CRITICAL: Not working
		#$MultiplayerSynchronizer.set_visibility_for(peer_uid, false)
		#$MultiplayerSynchronizer.update_visibility(0)
		#return

	if multiplayer.is_server():
		weapons_manager.update_ammo_signal.connect(update_ammo)

	# Connect signals, only on the server.
	# Control visibility via syncronizer.
	#if multiplayer.is_server():

	# TESTING: Here we have our exact client listen for signals (emitted in rpc_id)
	# This is client side. Could get messy. Or could work for UI.
	if str(peer_uid) == get_parent().name:
		var player_health_system: HealthSystem = get_parent().health_system
		player_health_system.health_updated.connect(update_health)
		player_health_system.max_health_updated.connect(func (new_max): local_max_health = new_max)
	

func _process(_delta: float) -> void:
	_show_snow_shader()

func update_health(new_health):
	health_label.text = str(new_health) + " / " + str(local_max_health)
	health_bar.value = new_health
	health_bar.max_value = local_max_health

func update_ammo(current_ammo: int, reserve_ammo: int):
	%CurrentAmmo.set_text(str(current_ammo)+" / "+str(reserve_ammo))

func update_weapon(weapon_name: String):
	%CurrentWeaponLabel.set_text(weapon_name)

# TODO: Refactor. We do not support having more than 2 weapons.
func update_previous_weapon(weapon_name: String):
	%BackupWeaponLabel.set_text(weapon_name)

func update_previous_ammo(ammo: Array[int]):
	%BackupAmmo.set_text(str(ammo[0])+" / "+str(ammo[1]))

func _on_weapons_manager_hit_signal():
	hit_sight.set_visible(true)
	hit_sight_timer.start()

func _on_hit_sight_timer_timeout():
	hit_sight.set_visible(false)

# DEPRECATED: These are from the previous template. May be useful.
#func load_over_lay_texture(Active:bool, txtr: Texture2D = null):
		#overlay.set_texture(txtr)
		#overlay.set_visible(Active)

#func _on_weapons_manager_connect_weapon_to_hud(_weapon_resouce: WeaponResource):
	#_weapon_resouce.update_overlay.connect(load_over_lay_texture)

#func _on_weapons_manager_update_weapon_stack(WeaponStack):
	#current_weapon_stack.text = ""
	#for i in WeaponStack:
		#current_weapon_stack.text += "\n"+i.weapon.weapon_name

# TODO: Emit a singal when inside heat dome if other systems need to know
func _show_snow_shader():
	if Hub.heat_dome:
		if get_parent().global_position.distance_to(Hub.heat_dome.global_position) <= Hub.heat_dome.heat_dome_radius:
			if snow_shader.visible == true: snow_shader.visible = false
		else:
			if snow_shader.visible == false: snow_shader.visible = true

@rpc
func update_interaction_label(interactable_name: String):
	%InteractLabel.text = interactable_name
