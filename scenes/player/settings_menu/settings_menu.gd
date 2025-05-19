extends Control

# settings
@onready var sensitivity_slider: HSlider = %SensitivitySlider
@onready var master_slider: HSlider = %Master
#@onready var sfx_slider: HSlider = $MarginContainer/Panel/MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer2/SFX
#@onready var background_slider: HSlider = $MarginContainer/Panel/MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer2/BackgroundSlider

var bus_master = AudioServer.get_bus_index("Master")
#var bus_sfx = AudioServer.get_bus_index("SFX")
#var bus_echo = AudioServer.get_bus_index("Echo")
#var bus_background = AudioServer.get_bus_index("Background")

var camera_sensitivity: float 

var volume_master_value
var volume_sfx_value
var volume_background_value

@onready var player: Player = get_parent().get_parent()

func _ready():
	visible = false

	player.main_menu_signal.connect(settings_menu_open)

	%Respawn.pressed.connect(_on_respawn_pressed)
	%Quit.pressed.connect(_on_quit_pressed)
	%PVPCheck.toggled.connect(_on_pvp_check_toggled)

	# TODO: DO THIS PROGRAMMATICALLY, USING AN ARRAY or ENUM THIS IS MADDENING the 2nd time aroudn
	# TODO: DO THIS PROGRAMMATICALLY, USING AN ARRAY or ENUM THIS IS MADDENING the 2nd time aroudn
	# TODO: DO THIS PROGRAMMATICALLY, USING AN ARRAY or ENUM THIS IS MADDENING the 2nd time aroudn
	# TODO: DO THIS PROGRAMMATICALLY, USING AN ARRAY, EXPORT whatever or ENUM THIS IS MADDENING the 2nd time aroudn	
	volume_master_value = db_to_linear(AudioServer.get_bus_volume_db(bus_master))
	#volume_sfx_value = db_to_linear(AudioServer.get_bus_volume_db(bus_sfx))
	#volume_background_value = db_to_linear(AudioServer.get_bus_volume_db(bus_background))
	
	# sliders
	master_slider.max_value = 1.0 * 2
	#sfx_slider.max_value = volume_sfx_value * 2
	#background_slider.max_value = volume_background_value * 2

	# values
	master_slider.value = volume_master_value
	#sfx_slider.value = volume_sfx_value
	#background_slider.value = volume_background_value
	Nodash.error_missing(player, 'player')
	#if player:
		#camera_sensitivity = player._camera_input.CAMERA_MOUSE_ROTATION_SPEED
		#sensitivity_slider.max_value = camera_sensitivity * 2
		#sensitivity_slider.value = camera_sensitivity

func settings_menu_open(is_open):
	if is_open == true:
		self.visible = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		self.visible = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_respawn_pressed():
	#toggleMenu()
	await get_tree().create_timer(0.2).timeout
	player.health_system.died.emit()

func _on_quit_pressed():
	get_tree().quit(0)

func _on_sensitivity_slider_value_changed(value):
	player.sensitivity = value
	#player.joystick_sensitivity = value

func _on_master_value_changed(value):
	AudioServer.set_bus_volume_db(bus_master, linear_to_db(value))
#
#func _on_sfx_value_changed(value):
	#AudioServer.set_bus_volume_db(bus_sfx, linear_to_db(value))
	#AudioServer.set_bus_volume_db(bus_echo, linear_to_db(value))
#
#func _on_background_value_changed(value):
	#AudioServer.set_bus_volume_db(bus_background, linear_to_db(value))
	
func _on_pvp_check_toggled(toggled_on):
	if player:
		player.update_pvp.rpc_id(1, toggled_on)
