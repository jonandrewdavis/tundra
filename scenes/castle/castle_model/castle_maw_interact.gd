extends Interactable

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	label = "Open Gate"

func interact(_player):
	if get_parent().open == false:
		get_parent().open_maw.emit()
		return true

	return false
