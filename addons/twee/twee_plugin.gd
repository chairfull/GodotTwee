@tool
extends EditorPlugin

var inspector_plugin := preload("twee_inspector.gd").new()

func _enter_tree():
	add_inspector_plugin(inspector_plugin)

func _exit_tree():
	remove_inspector_plugin(inspector_plugin)
