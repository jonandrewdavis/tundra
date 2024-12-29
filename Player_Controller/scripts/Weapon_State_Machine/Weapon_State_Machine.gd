extends Node3D

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
@export var weapons_list: Array[WeaponSlot]

# A list, 0 - 5
@export var weapons_owned: Array[WEAPONS] 

# Indexes into -> weapons_list -> weapons_owned to retrieve the WeaponResource
@export var weapon_index: int = 0

var player_camera_3D: Camera3D
var busy = false

func _ready() -> void:
	weapons_owned = [WEAPONS.blasterL, WEAPONS.blasterN]

func get_weapon(index: int) -> WeaponResource:
	return weapons_list[weapons_owned[index]].weapon

# TODO: Could use signals here to update multiple things, like HUD, etc.
# TODO: Decide if we want to emit the current "WeaponSlot" (might be helpful for HUD)
# TODO: Should reject if an action is currently running
func change_weapon(dir: CHANGE_DIR) -> void:
	if dir == CHANGE_DIR.UP:
		weapon_index = max(weapon_index - 1, 0)
		var new_weapon = get_weapon(weapon_index)
		animation_player.play(new_weapon.pick_up_animation)
		weapon_changed.emit()

	if dir == CHANGE_DIR.DOWN:
		var new_weapon = get_weapon(weapon_index)
		weapon_index = min(weapon_index + 1, weapons_owned.size() - 1)
		weapon_changed.emit()
