@tool
extends Node

signal event(str: String)

@export var tweeny: Tweeny:
	set(t):
		tweeny = t
		if tweeny and not Engine.is_editor_hint(): tweeny.changed.connect(tweeny.run.bind(self, &"_tween"))
@export_tool_button("Run") var run=func(): if tweeny: tweeny.run(self, &"_tween")
@export_tool_button("Kill") var kill=func(): if _tween: _tween.kill()
@export_tool_button("Pause/Resume") var pause=func():
	if _tween:
		if _tween.is_running():
			_tween.pause()
		else:
			_tween.play()

var _tween: Tween

func _ready() -> void:
	if not Engine.is_editor_hint():
		if tweeny: tweeny.run(self, &"_tween")
	else:
		event.connect(print)
