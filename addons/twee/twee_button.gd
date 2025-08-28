@tool
class_name TweeButton extends TweeNode
## Meant to be a child of the TweeButtonList

signal other_chosen() ## Different node was chosen. Meant for a fade out.
signal chosen() ## I was chosen. Meant for a fade out.

func _ready() -> void:
	if not get_parent() is TweeButtonList:
		push_warning("TweeButton meant to be child of TweeButtonList")
	super()
