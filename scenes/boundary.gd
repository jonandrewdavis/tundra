extends Node3D

@onready var boundary_area = $BoundaryArea
@onready var death_area = $DeathArea

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	boundary_area.body_entered.connect(_on_boundary_entered)
	death_area.body_entered.connect(_on_death_entered)
	
func _on_boundary_entered(body):
	return
	
func _on_death_entered(body):
	if body.has_method('death'):
		body.death()
