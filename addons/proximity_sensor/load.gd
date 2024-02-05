@tool
extends EditorPlugin

const Name = "ProximitySensor"
func _enter_tree() -> void:
	add_custom_type(Name,"Node3D",preload("script.gd"),preload("icon.svg"))

func _exit_tree() -> void: 
	remove_custom_type(Name)

