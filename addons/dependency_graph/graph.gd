@tool
extends GraphEdit

var interface: EditorInterface

func _ready() -> void:
	get_menu_hbox().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var line_edit := LineEdit.new()
	line_edit.custom_minimum_size.x = 480
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.placeholder_text = "Root resource/directory here. (default=res://)"
	line_edit.right_icon = interface.get_base_control().get_theme_icon(&"NewRoot", &"EditorIcons")
	get_menu_hbox().add_child(line_edit)
