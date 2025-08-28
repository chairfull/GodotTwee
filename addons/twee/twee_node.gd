@tool
class_name TweeNode extends Node
## Applies a list of Twees to a Node.

signal event(str: String)

@export_storage var twees: Array[Twee] = [Twee.new()]:
	set(t):
		twees = t
		notify_property_list_changed()
@export_storage var playing := false
@export_tool_button("Reload") var _tool_reload := reload
@export_tool_button("Kill") var _tool_kill := kill
@export_tool_button("Pause/Resume") var _took_toggle_play := func(): pause() if playing else play()

func _ready() -> void:
	if not Engine.is_editor_hint():
		reload()
	else:
		event.connect(print)

func play():
	playing = true
	for twn in twees:
		if twn and not twn.is_running(self):
			twn.play(self)

func pause():
	playing = false
	for twn in twees:
		if twn and twn.is_running(self):
			twn.pause(self)

func reload():
	playing = true
	for twn in twees:
		if twn: twn.reload(self)

func kill():
	playing = false
	for twn in twees:
		if twn: twn.kill(self)
	for meta_key in get_meta_list():
		if meta_key.begins_with("tweeny"):
			set_meta(meta_key, null)

#region Editor

func _get(property: StringName) -> Variant:
	if property.begins_with("_TWEE_"):
		var parts := property.trim_prefix("_TWEE_").rsplit("_", true, 1)
		var index := int(parts[1])
		return twees[index][parts[0]]
	return null

func _set(property: StringName, value: Variant) -> bool:
	if property.begins_with("_TWEE_"):
		var parts := property.trim_prefix("_TWEE_").rsplit("_", true, 1)
		var index := int(parts[1])
		twees[index][parts[0]] = value
		return true
	return false

func _property_can_revert(property: StringName) -> bool:
	if property.begins_with("_TWEE_"):
		var parts := property.trim_prefix("_TWEE_").rsplit("_", true, 1)
		return parts[0] in Twee.new()
	return false

func _property_get_revert(property: StringName) -> Variant:
	if property.begins_with("_TWEE_"):
		var parts := property.trim_prefix("_TWEE_").rsplit("_", true, 1)
		return Twee.new().get(parts[0])
	return null

func _get_property_list() -> Array[Dictionary]:
	var props: Array[Dictionary]
	for i in twees.size():
		var twee := twees[i]
		if not twee: continue
		props.append({ name="_TWEE_code_%s"%i, type=TYPE_STRING, hint=PROPERTY_HINT_EXPRESSION })
	props.append({ name="twees", type=TYPE_ARRAY, hint=PROPERTY_HINT_ARRAY_TYPE, hint_string="Twee" })
	return props

#endregion
