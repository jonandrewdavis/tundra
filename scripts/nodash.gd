extends Node

func _format_stack():
	var s = get_stack()[2] # the calling node.
	return " @ ".join(["", s.source.get_file(), s.function, s.line]	)

## Warn if the given node is missing
func warn_missing(node: Node, node_name: String):
	if !node:
		push_warning('Missing: ', node_name, _format_stack())

## Throw an error if the given node is missing
func error_missing(node: Node, node_name: String):
	if !node:
		push_error('Missing: ', node_name, _format_stack())



# TODO: accept just a string OR a string array to get fancy & set more at once. 
## Add a property to a MultiplayerSynchronizer using code instead of UI. Default replication mode is "On Change".
# NOTE: Keep in mind that REPLICATION_MODE_ON_CHANGE will send updates RELIABLY, which comes with a large performance/latency penalty
func sync_property(sync: MultiplayerSynchronizer, node: Node, properties: Array[String], on_change: bool = true):
	var node_path = str(node.get_path()) + ':' + ":".join(properties)
	
	# Any resource we update via code should be local to scene or it could cause issues when freeing
	if sync.replication_config.resource_local_to_scene == false:
		sync.replication_config.resource_local_to_scene = true

	sync.replication_config.add_property(node_path)
	if on_change:
		sync.replication_config.property_set_replication_mode(node_path, SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
	else:
		sync.replication_config.property_set_replication_mode(node_path, SceneReplicationConfig.REPLICATION_MODE_ALWAYS)

## Remove all properties from a MultiplayerSynchronizer. Useful during on_exit clean up to prevent errors.
func sync_remove_all(sync: MultiplayerSynchronizer):
	for property: NodePath in sync.replication_config.get_properties():
		sync.replication_config.remove_property(property)
