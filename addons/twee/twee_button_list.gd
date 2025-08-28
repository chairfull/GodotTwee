@tool
class_name TweeButtonList extends TweeNode

signal pressed(id: StringName)

func _ready() -> void:
	if not Engine.is_editor_hint():
		for child in get_children():
			if child.has_signal(&"pressed"):
				child.pressed.connect(_pressed.bind(child.name))
	super()

func _pressed(id: StringName):
	for child in get_children():
		if child is TweeButton:
			if child.name == id:
				child.chosen.emit()
			else:
				child.other_chosen.emit()

func disable(...args):
	for child in get_children():
		if child is Button:
			child.text = str(args)
			child.disabled = true

func quit():
	get_tree().quit()
