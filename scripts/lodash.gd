extends Node

func _format_stack():
	var s = get_stack()[2] # the calling node.
	return " @ ".join(["", s.source.get_file(), s.function, s.line]	)

func warn(node: Node, node_name: String):
	if !node:
		push_warning('Missing: ', node_name, _format_stack())
		
func error(node: Node, node_name: String):
	if !node:
		push_error('Missing: ', node_name, _format_stack())

# TODO: accept a string or a string array for properties
func sync_property(sync: MultiplayerSynchronizer, node: Node, properties: Array[String], on_change: bool = false):
	var node_path = str(node.get_path()) + ':' + ":".join(properties)
	sync.replication_config.add_property(node_path)
	if on_change:
		sync.replication_config.property_set_replication_mode(node_path, SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
