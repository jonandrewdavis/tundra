extends Node3D

# TODO: Max value
@export var heat_dome_radius: int = 20

# Controls how far the 2nd ring goes
const spread = 100

@onready var fog_volume_1 = $FogVolumes/FogVolume1
@onready var fog_volume_2 = $FogVolumes/FogVolume2

@onready var interior: MeshInstance3D = $HeatDomeInterior
@onready var exterior: MeshInstance3D = $HeatDomeExterior
# Helps with types
@onready var interior_mesh: SphereMesh = $HeatDomeInterior.mesh
@onready var exterior_mesh: SphereMesh = $HeatDomeExterior.mesh

@onready var sync:SceneReplicationConfig = $MultiplayerSynchronizer.replication_config

# TODO: New areas. If hte player is in it, out of it/ hurt. etc. cold
# TODO: Set visiblity range fade mode & fix the shader to be compatbile.
func _ready() -> void:
	Hub.heat_dome = self

	fog_volume_1.material.density = -0.5
	fog_volume_2.material.density = -0.3

	exterior.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	interior.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	sync_all_properties()

	# The heat dome is server authoratitive
	# Use MultiplayerSync to broadcast value changes to clients
	if not multiplayer.is_server():
		set_process(false)
		return

	heat_dome_radius = 20
	Hub.heat_dome_value.connect(on_change_heat_dome_value)
	on_change_heat_dome_value(0)
	
# TODO: It's possible that we want:
# 1: FogVolume1: None
# 2: world fog
# 3: FogVolume2: "death fog" on the edges

# TODO: Gradual decay without fuel
func _process(_delta: float) -> void:
	pass

func sync_path(node: Node3D, properties: Array[String]):
	sync.add_property(str(node.get_path()) + ':' + ":".join(properties)
)

# TODO: Better abstration so we can call it once.
func sync_all_properties():
	sync_path(fog_volume_1, ['size'])
	sync_path(fog_volume_2, ['size'])

	sync_path(interior, ['mesh', 'radius']) #: Syntax should be: node, str, str, str
	sync_path(exterior, ['mesh', 'radius'])
	sync_path(interior, ['mesh', 'height'])
	sync_path(exterior, ['mesh', 'height'])
	
	sync_path(interior, ['visibility_range_end'])
	sync_path(interior, ['visibility_range_end_margin'])
	sync_path(exterior, ['visibility_range_end'])
	sync_path(exterior, ['visibility_range_end_margin'])

	for property_path in sync.get_properties():
		sync.property_set_replication_mode(property_path, SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)	

# TODO: Lerp so it smoothly expands.
func on_change_heat_dome_value(value: int = 0):
	heat_dome_radius = heat_dome_radius + value
	
	interior_mesh.radius = heat_dome_radius
	interior_mesh.height = heat_dome_radius
	exterior_mesh.radius = heat_dome_radius
	exterior_mesh.height = heat_dome_radius
	
	interior.visibility_range_end = heat_dome_radius
	interior.visibility_range_end_margin = heat_dome_radius + spread - 50 # fade sooner
	exterior.visibility_range_end = heat_dome_radius
	exterior.visibility_range_end_margin = heat_dome_radius + spread - 50 # fade sooner

	fog_volume_1.size.x = heat_dome_radius * 2
	fog_volume_1.size.z = heat_dome_radius * 2
	
	fog_volume_2.size.x = heat_dome_radius * 2 + spread
	fog_volume_2.size.z = heat_dome_radius * 2 + spread
