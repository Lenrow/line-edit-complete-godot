@tool
extends Button

signal option_chosen(option_text)

func _pressed() -> void:
	emit_signal("option_chosen", get_parent().get_node("CompleteText").text)
