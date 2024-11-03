class_name CompleteMenu
extends Control

const DEF_SIZE_MULT = Vector2(1, 4)
const DEF_SIZE_MIN = Vector2(100, 0)

@export var complete_nodes: Array[Control]
var all_nodes: Array[Control]
var edit: LineEdit

var node_margin: float = 3
var node_size: float : 
	get:
		var size_y = 0
		for node in complete_nodes:
			size_y += node.size.y
		size_y += (complete_nodes.size()) * node_margin
		return size_y
var anchor_point: Vector2
var main_direction: Enums.Direction
var max_size: Vector2
@export var grow_upwards: bool = false
var anchor_east: bool = false

var current_term: String = ""

#region control_vars
var is_in_focus: bool
var is_in_selection: bool
#endregion

var option_scene = preload("res://Scenes/complete_option.tscn")

@onready var option_holder: Control = $ScrollContainer/OptionHolder
@onready var scroll_container: ScrollContainer = $ScrollContainer

func set_up_menu(placement_point: Vector2, direction_main, direction_sub, maximum_size: Vector2, line_edit: LineEdit):
	edit = line_edit
	var edit_rect: Rect2 = line_edit.get_global_rect()
	main_direction = direction_main
	anchor_point = placement_point
	grow_upwards = direction_sub == Enums.Direction.NORTH
	anchor_east = direction_main == Enums.Direction.EAST

	max_size = maximum_size
	resize(edit.size * DEF_SIZE_MULT)

	edit.connect("text_changed", refresh_nodes)
	refresh_nodes("")

func load_terms(terms: Array):
	for term: String in terms:
		var option = option_scene.instantiate()
		option_holder.add_child(option)
		option.get_node("CompleteText").text = term
		option.get_node("Button").connect("option_chosen", on_option_chosen)
		all_nodes.append(option)
	
	refresh_nodes(current_term)

func resize(new_size= null):
	if new_size == null:
		new_size = Vector2(edit.size.x * DEF_SIZE_MULT.x, min(edit.size.y * DEF_SIZE_MULT.y, node_size))
		new_size = DEF_SIZE_MIN.max(new_size)
	if max_size:
		size = max_size.min(new_size)
	else:
		size = new_size
	calc_anchor_point()
	position = anchor_point
	

func calc_anchor_point():
	match main_direction:
		Enums.Direction.NORTH:
			anchor_point = edit.global_position - Vector2(0, get_rect().size.y)
		Enums.Direction.EAST:
			anchor_point = Vector2(edit.get_global_rect().end.x, edit.global_position.y)
			anchor_point.y -= (get_rect().size.y - edit.size.y) if grow_upwards else 0.
		Enums.Direction.SOUTH:
			anchor_point = Vector2(edit.global_position.x, edit.get_global_rect().end.y)
			pass
		Enums.Direction.WEST:
			anchor_point = Vector2(edit.global_position.x - get_rect().size.x, edit.global_position.y)
			anchor_point.y -= (get_rect().size.y - edit.size.y) if grow_upwards else 0.

func reposition_nodes(ordered_nodes: Array[Control]):
	complete_nodes = ordered_nodes
	var holder_size = node_size
	var grow_indicator = -1 if grow_upwards else 1 # used instead of if-else everytime addition/subtraction is used
	option_holder.set_custom_minimum_size(Vector2(0, holder_size))
	var current_position = Vector2(0, holder_size) if grow_upwards else Vector2(0, 0)
	for node in ordered_nodes:
		node.position = current_position
		node.position.y -= node.size.y if grow_upwards else 0.
		node.size.x = option_holder.size.x
		current_position.y += grow_indicator * (node.size.y + node_margin)

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
	current_term = text

	if text.is_empty():
		complete_nodes = all_nodes
	else:
		complete_nodes = all_nodes.filter(func(x): return text in get_option_text(x))
		for node in all_nodes.filter(func(x): return not text in get_option_text(x)):
			node.visible = false
	complete_nodes.assign(complete_nodes.map(func(x): x.visible = true; return x))


	complete_nodes.sort_custom(compare_options)
	

	reposition_nodes(complete_nodes)
	if grow_upwards:
		scroll_container.set_deferred("scroll_vertical", scroll_container.get_v_scroll_bar().max_value)
	
	resize()
	if complete_nodes:
		edit.focus_neighbor_top = complete_nodes[0].get_node("Button").get_path()
		complete_nodes[0].get_node("Button").focus_neighbor_bottom = edit.get_path()

func show_menu():
	self.visible = true
	refresh_nodes(current_term)
	is_in_focus = true
	is_in_selection = false

func hide_menu(override = false):
	if is_in_selection and not override:
		return
	self.visible = false
	is_in_focus = false

func on_option_chosen(text):
	var r_text = edit.text
	edit.text = r_text.substr(0, (r_text.rfind(current_term))) + text
	print(r_text.substr(0, (r_text.rfind(current_term))), " ", (r_text.rfind(current_term)))

func get_option_text(option: Control):
	return option.get_node("CompleteText").text

func compare_options(a, b):
	a = get_option_text(a)
	b = get_option_text(b)

	var score = 0
	score = b.length() - a.length()
	score += b.find(current_term) - a.find(current_term)
	#print("a: ", a, " | b:", b, "\na length: ", a.length(), " | b length:", b.length(),"\na term pos: ", a.find(current_term), " | b term pos:", b.find(current_term), "\n score:", score, "\n" )

	return score > 0

func print_nodes():
	print(complete_nodes.map(func(x): return get_option_text(x)))

func _input(event):
	if event is InputEventKey:
		
		if event.is_action_pressed("ui_up") and not is_in_selection:
			get_viewport().set_input_as_handled()
			is_in_selection = true
			get_node(edit.focus_neighbor_top).grab_focus()
			
		
		if event.is_action_pressed("ui_down") and is_in_selection:
			is_in_selection = false
