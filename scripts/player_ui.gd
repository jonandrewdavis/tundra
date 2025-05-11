extends CanvasLayer
class_name PlayerUI

@export var weapons_manager: WeaponsManager
@export var health_bar: ProgressBar
@export var health_label: Label

@export var temp_bar: ProgressBar
@export var temp_label: Label

# TODO: When UI items move around, they're often reparented...
# Use the export & select method above. It keeps them current.
# Alternatively, use "access as unique name", which is kinda the same effect.
@onready var hit_sight = $HitSight
@onready var snow_shader_light = $Shaders/SnowShaderLight
@onready var snow_shader_heavy = $Shaders/SnowShaderHeavy

var player_health_system: HealthSystem

var local_health: int = 100
var local_max_health: int = 100

# TODO: Is this the best place for these?
# TODO: Weapon stack, current weapon, current weapon image
var hit_sight_timer = Timer.new()

func _ready():
	var peer_id = get_parent().name.to_int()

	# CRITICAL: If we're not server, and NOT the player that owns the UI. 
	# Delete the UI and return early.
	if not multiplayer.is_server() and multiplayer.get_unique_id() != peer_id:
		queue_free()
		return

	if multiplayer.is_server():
		Hub.projectile_system.hit_signal.connect(handle_hit_signal)

		weapons_manager.update_ammo_signal.connect(func(curr, res): update_ammo.rpc_id(peer_id, curr, res))
		weapons_manager.update_weapon_signal.connect(func(text): update_weapon.rpc_id(peer_id, text))
		weapons_manager.update_ammo_prev_signal.connect(func(curr, res): update_ammo_prev.rpc_id(peer_id, curr, res))
		weapons_manager.update_weapon_prev_signal.connect(func(text): update_weapon_prev.rpc_id(peer_id, text))

		player_health_system = get_parent().health_system
		# Health
		player_health_system.health_updated.connect(func(new_health): update_health.rpc_id(peer_id, new_health))
		player_health_system.max_health_updated.connect(func (new_max): update_max_health.rpc_id(peer_id, new_max))

		# Temp
		player_health_system.temp_updated.connect(func (new_temp): update_temp.rpc_id(peer_id, new_temp))
		player_health_system.update_fog.connect(func (new_fog_value): on_update_fog.rpc_id(peer_id, new_fog_value))
		
		# TODO: Listen for death and fade out UI? 
	else:
		# Client code
		DebugMenu.style = DebugMenu.Style.VISIBLE_DETAILED
	
		# Only clients need hit sight timer. RPC just starts it.
		add_child(hit_sight_timer)
		hit_sight_timer.wait_time = 0.05
		hit_sight_timer.one_shot = true
		hit_sight_timer.timeout.connect(_on_hit_sight_timer_timeout)
		
		%TempBar.max_value = 76.0
		%TempBar.min_value = -40.0

func _process(_delta: float) -> void:
	_show_snow_shader()

func handle_hit_signal(source):
	if source == get_parent().name.to_int():
		show_hit_signal.rpc_id(source)

@rpc
func show_hit_signal():
	hit_sight.set_visible(true)
	hit_sight_timer.start()	

func _on_hit_sight_timer_timeout():
	hit_sight.set_visible(false)
	
@rpc
func update_health(new_health):
	health_label.text = str(new_health) + " / " + str(local_max_health)
	local_health = new_health
	health_bar.value = new_health
	
@rpc
func update_max_health(new_max_health):
	health_label.text = str(local_health) + " / " + str(new_max_health)
	local_max_health = new_max_health
	health_bar.max_value = new_max_health

@rpc
func update_ammo(current_ammo: int, reserve_ammo: int):
	%CurrentAmmo.set_text(str(current_ammo)+" / "+str(reserve_ammo))

@rpc
func update_weapon(weapon_name: String):
	%CurrentWeaponLabel.set_text(weapon_name)

@rpc
func update_weapon_prev(weapon_name: String):
	%BackupWeaponLabel.set_text(weapon_name)

@rpc
func update_ammo_prev(current_ammo: int, reserve_ammo: int):
	%BackupAmmo.set_text(str(current_ammo)+" / "+str(reserve_ammo))

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

# TODO: SOURCE THESE FROM HEAT DOME! OR HEAT SYSTEM and emit here.
func _show_snow_shader():
	if Hub.castle && Hub.castle.heat_dome:
		var player_heat_distance = get_parent().global_position.distance_to(Hub.castle.heat_dome.global_position)
		var dome_and_spread = Hub.castle.heat_dome.heat_dome_radius + 15
				
		if player_heat_distance <= Hub.castle.heat_dome.heat_dome_radius:
			if snow_shader_light.visible == true: snow_shader_light.visible = false
			if snow_shader_heavy.visible == true: snow_shader_heavy.visible = false
		elif player_heat_distance >= Hub.castle.heat_dome.heat_dome_radius and\
			player_heat_distance <= dome_and_spread:
			if snow_shader_light.visible == false: snow_shader_light.visible = true
			if snow_shader_heavy.visible == true: snow_shader_heavy.visible = false
		else:
			if snow_shader_light.visible == true: snow_shader_light.visible = false
			if snow_shader_heavy.visible == false: snow_shader_heavy.visible = true

@rpc
func update_interaction_label(interactable_name: String):
	%InteractLabel.text = interactable_name

@rpc
func update_temp(new_temp: float):
	var tween = create_tween()
	tween.tween_property(%TempBar, "value", new_temp, 1.0)

@rpc
func on_update_fog(new_fog: float):
	var fog_resource = Hub.world.world_env
	var tween = create_tween()
	tween.tween_property(fog_resource, "environment:volumetric_fog_density", new_fog, 1.0)
