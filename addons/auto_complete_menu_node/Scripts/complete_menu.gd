@tool
class_name CompleteMenu
extends Control

var visible_nodes: Array[Control] ## all the term-nodes that are currently visible
var all_nodes: Array[Control] ## all the term nodes, one for each term
var edit: LineEdit ## the edit this menu applies to

## defines the size of the menu, in relation to the edit
## if this was (1,1) the menu would have the same size as the edit
var size_mult = Vector2(1, 4) 
var size_min = Vector2(100, 0)
var edit_margin = 0
var node_margin_y: float = 3
var node_size: float : 
	get:
		var size_y = 0
		for node in visible_nodes:
			size_y += node.size.y
		size_y += (visible_nodes.size()) * node_margin_y
		return size_y
var anchor_point: Vector2 ## position is calculated relative to edit by resize
var main_direction: Enums.Direction ## main menu direction
var max_size: Vector2
var grow_upwards: bool = false 

var use_edit_font_size: bool

var current_text: String = "" ## the text that is currently checked. Not entire edit text if whitespaces are there
var all_active_terms: Array = [] ## all loaded terms in one array

#region control_vars
var is_in_focus: bool
var is_in_selection: bool
#endregion

var option_scene = preload("res://addons/auto_complete_menu_node/Scenes/complete_option.tscn")

@onready var option_holder: Control = $ScrollContainer/OptionHolder
@onready var scroll_container: ScrollContainer = $ScrollContainer

func set_up_menu(placement_point: Vector2, direction_main, direction_sub, maximum_size: Vector2, line_edit: LineEdit):
	edit = line_edit
	main_direction = direction_main
	anchor_point = placement_point
	grow_upwards = direction_sub == Enums.Direction.NORTH

	max_size = maximum_size
	resize(edit.size * size_mult)

	edit.connect("text_changed", refresh_nodes)
	refresh_nodes("")

## loads the [param terms] as new option nodes [br]
## if [param override_terms] is true all the prior existing terms are removed
func load_terms(terms: Array, override_terms=false):
	if override_terms:
		remove_terms(all_active_terms)
	if terms:
		var base_option = option_scene.instantiate()
		if use_edit_font_size:
			var theme_font_size = edit.get_theme_font_size("font_size")
			var label_settings_obj = base_option.get_node("CompleteText").label_settings
			if theme_font_size:
				label_settings_obj.font_size = theme_font_size
			else:
				label_settings_obj.font_size = edit.get_theme_default_font_size()
		for term: String in terms:
			if term in all_active_terms:
				continue
			var option = base_option.duplicate()
			option_holder.add_child(option)
			option.get_node("CompleteText").text = term
			option.get_node("Button").connect("option_chosen", on_option_chosen)
			all_nodes.append(option)

	all_active_terms.append_array(terms)
	refresh_nodes(current_text)

func remove_terms(terms: Array):
	var remove_nodes = []
	for node in all_nodes:
		if get_option_text(node) in terms:
			remove_nodes.append(node)
	
	visible_nodes = visible_nodes.filter(func(x): return not x in remove_nodes)
	all_nodes = all_nodes.filter(func(x): return not x in remove_nodes)
	all_active_terms = all_active_terms.filter(func(x): return not x in terms)
	for node in remove_nodes:
		node.queue_free()
	
	refresh_nodes(current_text)
		
## recalculates size and position
func resize(new_size= null):
	if new_size == null:
		new_size = Vector2(edit.size.x * size_mult.x, min(edit.size.y * size_mult.y, node_size))
		new_size = size_min.max(new_size)
	if max_size:
		set_deferred("size", max_size.min(new_size))
	else:
		set_deferred("size", new_size)
	calc_anchor_point()
	position = anchor_point
	

func calc_anchor_point():
	match main_direction:
		Enums.Direction.NORTH:
			anchor_point = edit.global_position - Vector2(0, get_rect().size.y + edit_margin)
		Enums.Direction.EAST:
			anchor_point = Vector2(edit.get_global_rect().end.x + edit_margin, edit.global_position.y)
			anchor_point.y -= (get_rect().size.y - edit.size.y) if grow_upwards else 0.
		Enums.Direction.SOUTH:
			anchor_point = Vector2(edit.global_position.x, edit.get_global_rect().end.y + edit_margin)
		Enums.Direction.WEST:
			anchor_point = Vector2(edit.global_position.x - get_rect().size.x - edit_margin, edit.global_position.y)
			anchor_point.y -= (get_rect().size.y - edit.size.y) if grow_upwards else 0.

## positions the nodes, based on the order they are given
func reposition_nodes(ordered_nodes: Array[Control]):
	visible_nodes = ordered_nodes
	var holder_size = node_size
	var grow_indicator = -1 if grow_upwards else 1 # used instead of if-else everytime addition/subtraction is used
	option_holder.set_custom_minimum_size(Vector2(0, holder_size))
	var current_position = Vector2(0, holder_size) if grow_upwards else Vector2(0, 0)
	for node in ordered_nodes:
		node.position = current_position
		node.position.y -= node.size.y if grow_upwards else 0.
		node.set_deferred("size", Vector2(option_holder.size.x, node.size.y))
		current_position.y += grow_indicator * (node.size.y + node_margin_y)

## sorts the nodes anew based on the new text and calls the reposition method
func refresh_nodes(text: String):
	var terms = text.split(" ")
	var t_length = 0
	var whitespace_i = 0
	# split up the currently selection completion term by whitespaces
	for term in terms:
		t_length += term.length()
		if t_length + whitespace_i >= edit.caret_column:
			text = term
			break
		whitespace_i += 1
	current_text = text

	if text.is_empty():
		visible_nodes = all_nodes
	else:
		visible_nodes = all_nodes.filter(func(x): return text in get_option_text(x))
		for node in all_nodes.filter(func(x): return not text in get_option_text(x)):
			node.visible = false
	visible_nodes.assign(visible_nodes.map(func(x): x.visible = true; return x))

	visible_nodes.sort_custom(compare_options)
	
	reposition_nodes(visible_nodes)
	if grow_upwards:
		scroll_container.set_deferred("scroll_vertical", scroll_container.get_v_scroll_bar().max_value)

	resize()
	if visible_nodes:
		if grow_upwards:
			edit.focus_neighbor_top = visible_nodes[0].get_node("Button").get_path()
			visible_nodes[0].get_node("Button").focus_neighbor_bottom = edit.get_path()
		else:
			edit.focus_neighbor_bottom = visible_nodes[0].get_node("Button").get_path()
			visible_nodes[0].get_node("Button").focus_neighbor_top = edit.get_path()
	show_menu(false)

func show_menu(refresh=true):
	self.visible = true
	if refresh:
		refresh_nodes(current_text)
	is_in_focus = true
	is_in_selection = false

func hide_menu(override = false):
	if is_in_selection and not override:
		return
	elif get_global_rect().has_point(get_global_mouse_position()) and not override:
		return
	self.visible = false
	is_in_focus = false

## applies the [param text] chosen in the menu to the edits text
## is called by the option_chosen signal in the option_button
func on_option_chosen(text):
	var text_parts = edit.text.split(" ")
	var t_length = 0
	var whitespace_i = 0
	var new_column_pos = edit.text.length()
	for i in text_parts.size():
		t_length += text_parts[i].length()
		if current_text == text_parts[i] and t_length + whitespace_i >= edit.caret_column:
			text_parts[i] = text
			new_column_pos = " ".join(PackedStringArray(text_parts.slice(0, i))).length() + text.length() + (0 if i == 0 else 1)
			break
		whitespace_i += 1
	edit.text = " ".join(PackedStringArray(text_parts))
	edit.grab_focus()
	edit.caret_column = new_column_pos
	hide_menu(true)


func get_option_text(option: Control):
	return option.get_node("CompleteText").text

func set_transform_values(margin, min_size, mult_size):
	if margin:
		edit_margin = margin
	if min_size:
		size_min = min_size
	if mult_size:
		size_mult = mult_size

func compare_options(a, b):
	a = get_option_text(a)
	b = get_option_text(b)

	var score = 0
	score = b.length() - a.length()
	score += b.find(current_text) - a.find(current_text)

	return score > 0

## makes it so the optionmenu can be navigated with the arrow keys, by interrupting default lineEdit key behavior
func _input(event):
	if event is InputEventKey:

		var select_nav_button = "ui_up" if grow_upwards else "ui_down"
		var back_nav_button = "ui_down" if grow_upwards else "ui_up"
		var edit_focus_neighbor = edit.focus_neighbor_top if grow_upwards else edit.focus_neighbor_bottom

		if not edit.has_focus():
			return

		if event.is_action_pressed(select_nav_button) and not is_in_selection and visible_nodes:
			get_viewport().set_input_as_handled()
			is_in_selection = true
			get_node(edit_focus_neighbor).grab_focus()
		
	
		if event.is_action_pressed(back_nav_button) and is_in_selection:
			is_in_selection = false
	
	if event is InputEventMouseButton:
		if event.is_released():
			if not (get_global_rect().has_point(get_global_mouse_position()) or edit.get_global_rect().has_point(get_global_mouse_position())):
				if edit.has_focus():
					edit.release_focus()
				else:
					hide_menu(true)
			
