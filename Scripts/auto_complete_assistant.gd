@tool
class_name AutoCompleteAssistant
extends Node

var test_strings = ["test1_example", "test_value", "sample_test", "alpha_test1", "test1_case",
	 "beta_test1", "gamma_test", "example_test", "test_case", "delta_test1", "test_version",
	  "test_example", "test_module_", "final_test1_", "test_example_","alpha_sample",
	   "demo_case", "example_value", "random_string", "case_study", "sample_data","alpha_beta",
		"project_name", "default_value", "core_module", "alpha_omega", "goofy ah test"]

var complete_menu = preload("res://Scenes/complete_menu.tscn")

## the line_edit nodes this node should spawn menus for
@export var line_edits: Array[LineEdit]
## the completion options (will probably be changed)
@export var completion_options: Array[String]
@export var allow_multi_word_completion: bool
## defines in which node the menu should be located. [br]
## This node has to contain the line_edit(s) you want it to appear for.
## Not necessarily as a parent but the edits must intersect with its global_rect
## since the menu will not cut out of this nodes boundaries
@export var menu_location_node: Control
## Nodes the menu should not cover. The menu will not spawn above these Nodes.
@export var not_cover_nodes: Array[Control] ## if too many are defined this might make menu too small.

var menus: Array[CompleteMenu]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	create_complete_menu(line_edits[0])

func create_complete_menu(edit: LineEdit):
	var location_info = get_location_boundaries(edit) # 0 is main direction as int (from enum) 1 is sub-direction so if north or south greater (for east-west) is max_size vector
	print(location_info)
	var direction = location_info[0]
	var placement_point = get_menu_placement_vec(edit, direction)
	var new_menu: CompleteMenu = complete_menu.instantiate()
	print(direction)
	add_child(new_menu)
	new_menu.set_up_menu(placement_point, direction, location_info[1], location_info[2], edit)
	new_menu.load_terms(test_strings)

	edit.connect("focus_entered", new_menu.show_menu)
	edit.connect("focus_exited", new_menu.hide_menu)
	menu_location_node.connect("resized", new_menu.resize)
	
	new_menu.hide_menu(true)


## calculates the free space available in all 4 directions of the LineEdit rect
## and the menu_location_node rect.
## If successful it returns a dictionary with the values
func get_location_boundaries(edit: LineEdit):
	if not menu_location_node or not edit:
		assert(false, "ERROR: NODE CONFIGURATION ERROR; LOCATION_NODE OR EDIT_NODE ARE NULL!")
		return null
	else:
		var location_rect = menu_location_node.get_global_rect()
		var edit_rect = edit.get_global_rect()
		print("Location Rect: ",location_rect, " End: ", location_rect.end,"\nEdit Rect:", edit_rect, " End: ", edit_rect.end)
		if not location_rect.intersects(edit_rect):
			assert(false, "ERROR: NODE CONFIGURATION ERROR; EDIT NOT WITHIN LOCATION_NODE")
			return null
		var direction_rects = Helpers.subtract_rects(location_rect, edit_rect)
		Helpers.print_collection(direction_rects, "Rects", true)
		var values = direction_rects["Values"]
		var max_value = 0
		var max_index = 0
		for i in values.size():
			var current_rect = values[i]
			if max_value <= current_rect.get_area():
				max_value = current_rect.get_area()
				max_index = i
		
		var max_size = direction_rects["Values"][max_index].size
		if max_index == 0 or max_index == 2:
			max_size.x = (location_rect.size - (edit_rect.position - location_rect.position)).x
		else:
			max_size.y = (location_rect.size - (edit_rect.position - location_rect.position)).y
			pass
		print(values[0].size.y, " | ",values[2].size.y)
		var vertical_direction = Enums.Direction.NORTH if values[0].size.y > values[2].size.y else Enums.Direction.SOUTH

		return [Enums.Direction[direction_rects.keys()[max_index]], vertical_direction, max_size]
		
func get_menu_placement_vec(edit: LineEdit, direction):
	var edit_rect = edit.get_global_rect()
	var return_vec
	match direction:
		Enums.Direction.EAST:
			return_vec = Vector2(edit_rect.end.x, edit_rect.position.y)
		Enums.Direction.SOUTH:
			return_vec = Vector2(edit_rect.position.x, edit_rect.end.y)
		_:
			return_vec = edit_rect.position
		
	# TODO: add margins or stuff
	return return_vec
