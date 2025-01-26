@tool
class_name Helpers
extends Object

const DIRECTION_STRINGS = ["NORTH", "EAST", "SOUTH", "WEST"]

## calculates the free space in 4 direction of a rect that should be within another rect. [br]
## [param sub_rect] is the rect that should be contained within the [param top_rect].[br]
## [b]returns[/b] Dictionary with each directional value with the keys [b]["NORTH", "EAST", "SOUTH", "WEST"][/b] [br]
## You can also access an Array of the 4 values arranged in NESW order with the key [b]["Values"][/b].
static func calculate_sub_rect_space(sub_rect, top_rect):
	var directions_dict = {}

	var position_rel = sub_rect.position - top_rect.position
	var directions = [position_rel.y , 0, 0, position_rel.x] # add north and west
	directions[1] = top_rect.size.x - (position_rel.x + sub_rect.size.x) # add east
	directions[2] = top_rect.size.y - (position_rel.y + sub_rect.size.y) # add south

	for i in DIRECTION_STRINGS.size(): # add values to dict
		directions_dict[DIRECTION_STRINGS[i]] = directions[i]

	directions_dict["Values"] = directions
	return directions_dict

## subtracts a [param sub_rect] from a [param base_rect] and returns a dict of up to 4 new rects around the subtracted rect. [br]
## The dict is the same as in the [calculate_sub_rect_space] func but with rects instead of distance values.[br]
## Values with area >= 0 or with size values under the [param size_threshold] will be returned as [b]null[/b]. [br]
## [param size_threshold] is a Vector2 and can be set,
## so all returned rects must have a higher-equal x/y value than specified in the vector.[br]
static func subtract_rects(base_rect: Rect2, sub_rect: Rect2, size_threshold: Vector2 = Vector2(0, 0)) -> Dictionary:
	var directions_dict = calculate_sub_rect_space(sub_rect, base_rect)
	var direction_rects = directions_dict["Values"]

	var return_dict = {}

	for i in direction_rects.size():
		# calculate rect_position
		var rect_pos = base_rect.position
		if i != 0 and i != 3:
			rect_pos = sub_rect.position + sub_rect.size
			rect_pos.x = base_rect.position.x if i % 2 == 0 else rect_pos.x
			rect_pos.y = base_rect.position.y if i % 2 == 1 else rect_pos.y
		
		var rect_size = base_rect.size
		if i == 0 or i == 3:
			rect_size.x = (sub_rect.position.x - base_rect.position.x) if i % 2 != 0 else base_rect.size.x
			rect_size.y = (sub_rect.position.y - base_rect.position.y) if (i + 1) % 2 != 0 else base_rect.size.y
		else:
			rect_size = base_rect.size - rect_pos
		
		rect_size = rect_size.max(Vector2(0, 0))
		direction_rects[i] = Rect2(rect_pos, rect_size)

		return_dict[DIRECTION_STRINGS[i]] = direction_rects[i] # add rect to return_dict

	return_dict["Values"] = direction_rects # add final rect array to return_dict
	return return_dict
		
	

static func print_collection(collection, name="Collection", add_separator=false, sep_max = 100):
	var type_collection = typeof(collection)
	if type_collection != TYPE_ARRAY and type_collection != TYPE_DICTIONARY:
		assert(false, "ERROR: ONLY ACCEPTS DICT/ARRAY VALUES")
		return
	
	var print_str: String = name + ":\n"
	var max_size = name.length() + 2
	var indent_size = max_size
	var keys = collection.keys() if type_collection == TYPE_DICTIONARY else null
	for i in collection.size():
		var indent = keys[i] if keys else " "
		indent = indent.rpad(indent_size, " ")
		var value = collection[keys[i]] if keys else collection[i]
		var value_line = "  " + indent + str(value) + "\n"
		if value_line.length() > max_size:
			max_size = value_line.length()
		print_str += value_line

	max_size = min(max_size, sep_max)

	if add_separator:
		print_str = "\n".lpad(max_size, "-") + print_str + "\n".lpad(max_size, "-")

	print(print_str)
