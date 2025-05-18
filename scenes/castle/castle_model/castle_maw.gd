extends Node3D

@onready var castle_maw_pivot = $CastleMawPivot
@onready var gullet: Area3D = $Gullet
@onready var open_maw_button: Interactable = $OpenMawButton

var target_basis_up = Basis.IDENTITY.rotated(Vector3.LEFT * -1.0, PI / 16)
var target_basis_down = Basis.IDENTITY.rotated(Vector3.LEFT * 1.0, PI / 5)

signal open_maw
var open = false
@onready var castle: MovingCastle = get_parent()

func _ready() -> void:
	castle_maw_pivot.basis = target_basis_up
	#create_tween().tween_method(interpolate, 0.0, 1.0, 5.0).set_trans(Tween.TRANS_EXPO)
	open_maw.connect(_on_open_maw)
	gullet.body_entered.connect(_on_detect_food)

func interpolate_down(weight):
	castle_maw_pivot.basis = castle_maw_pivot.basis.slerp(target_basis_down, weight)

func interpolate_up(weight):
	castle_maw_pivot.basis = target_basis_down.slerp(target_basis_up, weight)

func _on_open_maw():
	if open == false:
		play_open_sound.rpc()
		open = true
		open_maw_button.label = ''
		create_tween().tween_method(interpolate_down, 0.0, 1.0, 4.0).set_trans(Tween.TRANS_EXPO)
		await get_tree().create_timer(7.0).timeout
		create_tween().tween_method(interpolate_up, 0.0, 1.0, 4.0).set_trans(Tween.TRANS_EXPO)
		#play_open_sound.rpc()
		await get_tree().create_timer(3.0).timeout
		open = false
		open_maw_button.label = 'Open Gate'

# TODO: Fuel regen
func _on_detect_food(body):
	if body:
		castle.gain_fuel(55)
		body.set_process(false)
		body.queue_free()
		
@rpc
func play_open_sound():
	$MetalDoorOpen.play()
