@tool
class_name AutoCompleteAssistant
extends Node

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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var direction = get_location_boundaries(line_edits[0])
	var placement_point = get_menu_placement_vec(line_edits[0], direction)
	print(placement_point)


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
			if max_value >= current_rect.get_area():
				max_value = current_rect.get_area()
				max_index = i
		return Direction[direction_rects.keys()[max_index]]
		
func get_menu_placement_vec(edit: LineEdit, direction):
	var edit_rect = edit.get_global_rect()
	var return_vec
	match direction:
		Direction.EAST:
			return_vec = Vector2(edit_rect.end.x, edit_rect.position.y)
		Direction.SOUTH:
			return_vec = Vector2(edit_rect.position.x, edit_rect.end.y)
		_:
			return_vec = edit_rect.position
		
	# TODO: add margins or stuff
	return return_vec
