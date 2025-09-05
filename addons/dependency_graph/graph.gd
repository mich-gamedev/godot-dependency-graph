@tool
extends GraphEdit

var interface: EditorInterface
var nodes: Dictionary[String, GraphNode]

const GRAPH_NODE = preload("res://addons/dependency_graph/graph_node.tscn")

func _ready() -> void:
	if !interface: return
	add_theme_stylebox_override(&"panel", get_theme_stylebox(&"panel", &"Panel"))
	get_menu_hbox().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var line_edit := LineEdit.new()
	line_edit.custom_minimum_size.x = 480
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.placeholder_text = "Root resource/directory here. (default=res://)"
	line_edit.right_icon = interface.get_base_control().get_theme_icon(&"NewRoot", &"EditorIcons")
	get_menu_hbox().add_child(line_edit)
	line_edit.text_submitted.connect(_line_submitted)

func _line_submitted(text: String) -> void:
	clear_connections()
	for i in get_children():
		if i in nodes.values():
			i.queue_free()
			nodes.erase(nodes.find_key(i))
	(await _add_file(text)).set_slot_enabled_left(0, false)


func _add_file(file: String) -> GraphNode:
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

		var dependencies := ResourceLoader.get_dependencies(file)
		var _prev_n: Array[GraphNode] = []
		for i in dependencies.size():
			var path = dependencies[i].get_slice("::", 0)
			var dep_label := Label.new()
			dep_label.text = str(i)
			dep_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			inst.add_child(dep_label)
			inst.set_slot_enabled_right(i + 1, true)
			var node = nodes[path] if nodes.has(path) else await _add_file(path)
			node.set(&"position_offset", inst.position_offset + Vector2(inst.size.x + snapping_distance * 3, (_prev_n[-1].size.y + snapping_distance * 3 if !_prev_n.is_empty() else 0)))
			_prev_n.append(node)
			print(i)
			connect_node(inst.name, i, node.name, 0)
	else:
		inst.title = "Invalid! (%s)" % file.get_file()
		inst.set_slot_color_left(0, Color.RED)
		(inst.get_node(^"%Type") as Label).text = "Possible cyclic dependency, or incorrect path."
	return inst
