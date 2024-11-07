@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_custom_type("Auto Complete Assistant", "Node", preload("res://addons/auto_complete_menu_node/Scripts/auto_complete_assistant.gd"), preload("res://addons/auto_complete_menu_node/Assets/line-edit-complete-icon.png"), )


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass
