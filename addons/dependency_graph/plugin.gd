@tool
extends EditorPlugin

var inst: Control

func _enter_tree() -> void:
	var scene := load(get_plugin_file("graph.tscn")) as PackedScene
	inst = scene.instantiate()
	inst.interface = get_editor_interface()
	get_editor_interface().get_editor_main_screen().add_child(inst)
	_make_visible(false)

func _has_main_screen() -> bool:
	return true

func _get_plugin_name() -> String:
	return "DependencyGraph"

func _get_plugin_icon() -> Texture2D:
	return get_editor_interface().get_base_control().get_theme_icon("Filesystem", "EditorIcons")

func _make_visible(visible: bool) -> void:
	if is_instance_valid(inst):
		inst.visible = visible

func _exit_tree() -> void:
	inst.queue_free()

func get_plugin_dir() -> String:
	return (get_script() as Script).resource_path.get_base_dir()

func get_plugin_file(relative_path: String) -> String:
	return get_plugin_dir() + "/" + relative_path
