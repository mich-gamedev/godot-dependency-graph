@tool
extends GraphEdit

var interface: EditorInterface
var nodes: Dictionary[String, Control]

const GRAPH_NODE = preload("res://addons/dependency_graph/graph_node.tscn")

func _ready() -> void:
	add_theme_stylebox_override(&"panel", get_theme_stylebox(&"panel", &"Panel"))
	get_menu_hbox().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var line_edit := LineEdit.new()
	line_edit.custom_minimum_size.x = 480
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.placeholder_text = "Root resource/directory here. (default=res://)"
	if interface: line_edit.right_icon = interface.get_base_control().get_theme_icon(&"NewRoot", &"EditorIcons")
	get_menu_hbox().add_child(line_edit)
	line_edit.text_submitted.connect(_line_submitted)

func _line_submitted(text: String) -> void:
	clear_connections()
	for i in get_children():
		if i in nodes.values():
			i.queue_free()
	nodes.clear()
	(await _add_file(text))


func _add_file(file: String, _base_offset := Vector2()) -> GraphNode:
	var inst = GRAPH_NODE.instantiate()
	add_child(inst)
	var res := load(file)
	if res:
		inst.title = res.resource_path if !res.resource_name else "%s (%s)" % [res.resource_name, res.resource_path]
		var type = res.get_class()
		inst.get_node(^"%Icon").texture = get_theme_icon(type, &"EditorIcons")
		inst.get_node(^"%Type").text = type
		nodes[file] = inst

		await inst.resized
		inst.position_offset = _base_offset

		var dependencies := ResourceLoader.get_dependencies(file)
		var _last_n: GraphNode
		for i in dependencies.size():
			var path = dependencies[i].get_slice("::", 0)
			var dep_label := Label.new()
			dep_label.text = str(i + 1)
			dep_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			inst.add_child(dep_label)
			inst.set_slot_enabled_right(i + 1, true)
			if _last_n:
				_last_n.reset_size()
			await get_tree().process_frame
			var node = nodes[path] if nodes.has(path) else await _add_file(path, _base_offset + Vector2(inst.size.x + snapping_distance * 8, _last_n.position_offset.y + _last_n.get_combined_minimum_size().y + snapping_distance if _last_n else 0))
			print(_last_n.get_combined_minimum_size().y if _last_n else 0)
			connect_node(inst.name, i, node.name, 0)
			#node.position_offset = _base_offset + Vector2(inst.size.x + snapping_distance * 8, (_last_n.position_offset.y + _last_n.size.y + snapping_distance if _last_n else -dependencies.size() * 78. / 2.))
			_last_n = node
	else:
		inst.title = "Invalid! (%s)" % file.get_file()
		inst.set_slot_color_left(0, Color.RED)
		(inst.get_node(^"%Type") as Label).text = "Possible cyclic dependency, or incorrect path."
	return inst


func _on_child_entered_tree(node: Node) -> void:
	if node is GraphElement:
		await get_tree().process_frame
		node.reset_size()
