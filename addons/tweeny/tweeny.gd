@tool
class_name Tweeny extends Resource

const T_INDENT := &"INDENT"
const T_DEDENT := &"DEDENT"
const T_NEWLINE := &"NEWLINE"
const T_COLON := &":"
const T_LOOP := &"LOOP"
const T_WAIT := &"WAIT"
const T_STRING := &"STR"
const T_BLOCK := &"BLOCK"
const T_PARALLEL := &"PARALLEL"
const T_ON := &"ON"
const T_PROPERTIES_TWEENED := &"PROPS_TWEENED"
const T_PROPERTIES := &"PROPS"
const T_CHOICE := &"CHOICE" # TODO:
const T_WARP := &"WARP" # TODO:
const T_RELATIVE := &"+"
const T_RELATIVE_NEG := &"-"

@export_custom(PROPERTY_HINT_EXPRESSION, "") var tween: String:
	set(t):
		tween = t
		changed.emit()

@export_group("Defaults", "default_")
@export var default_tween_duration := 1.0 ## Default seconds to tween if a duration wasn't explicitly given.
@export var default_pause_duration := 1.0 ## Default seconds to wait if WAIT wasn't explicitly given.
@export var default_event_signal_or_method := &"event" ## Will attempt to pass "string" events to this.

@export var _target: NodePath
@export_tool_button("Test") var test := func():
	var toks := _tokenize(tween)
	var pars := _parse(toks)
	print(toks)
	print(JSON.stringify(pars[0], "\t", false))
	#DisplayServer.clipboard_set(JSON.stringify(pars[0], "\t", false))

func run(node: Node, tween_prop: StringName):
	var steps: Array = _parse(_tokenize(tween))[0]
	to_tween(node, tween_prop, steps)

func to_tween(node: Node, tween_prop: Variant, steps: Array) -> Tween:
	var twn: Tween = null
	for step in steps:
		match step.type:
			T_ON:
				for signal_id in step.args:
					node[signal_id].connect(func(): to_tween(node, tween_prop, step.children))
			T_PARALLEL:
				if not twn:
					twn = _tween(node, tween_prop)
				twn.set_parallel()
				to_tween(node, twn, step.children)
			T_BLOCK:
				if not twn:
					twn = _tween(node, tween_prop)
				to_tween(node, twn, step.children)
			T_LOOP:
				if twn:
					twn.set_loops(step.loop)
				else:
					push_error("No tween to repeat.")
			T_WAIT:
				if not twn:
					twn = _tween(node, tween_prop)
				twn.tween_interval(step.wait)
			T_STRING:
				# Call signal.
				if node.has_signal(default_event_signal_or_method):
					if not twn:
						twn = _tween(node, tween_prop)
					twn.tween_callback(node[default_event_signal_or_method].emit.bind(step.value))
				# Call method.
				elif node.has_method(default_event_signal_or_method):
					if not twn:
						twn = _tween(node, tween_prop)
					twn.tween_callback(node[default_event_signal_or_method].bind(step.value))
				else:
					push_warning("No event signal to emit.")
			T_PROPERTIES_TWEENED:
				if not twn:
					twn = _tween(node, tween_prop)
				var duration: float = step.duration
				var sub := node.create_tween()
				sub.set_parallel()
				for prop in step.props:
					var prop_info: Dictionary = step.props[prop]
					var result := _convert(node, prop, prop_info.vals)
					var pt: PropertyTweener
					match prop_info.get(&"relative"):
						T_RELATIVE: pt = sub.tween_property(node, prop, result, duration).as_relative()
						T_RELATIVE_NEG: pt = sub.tween_property(node, prop, -result, duration).as_relative()
						_: pt = sub.tween_property(node, prop, result, duration)
					var mode: StringName = step.get(&"mode", &"LINEAR")
					#print(mode, prop_inf)
					if mode != &"LINEAR" and mode != &"L":
						var parts := mode.split("_", true, 1)
						match parts[0]:
							"EASE", "E": pt.set_trans(Tween.TRANS_SINE)
							"EASEIN", "EI": pt.set_ease(Tween.EASE_IN)
							"EASEOUT", "EO": pt.set_ease(Tween.EASE_OUT)
							"EASEOUTIN", "EOI": pt.set_ease(Tween.EASE_OUT_IN)
						if parts.size() == 1:
							pt.set_trans(Tween.TRANS_SINE)
						else:
							match parts[1]:
								#"SINE": pt.set_trans(Tween.TRANS_SINE)
								"QUINT": pt.set_trans(Tween.TRANS_QUINT)
								"QUART": pt.set_trans(Tween.TRANS_QUART)
								"QUAD": pt.set_trans(Tween.TRANS_QUAD)
								"EXPO": pt.set_trans(Tween.TRANS_EXPO)
								"ELASTIC": pt.set_trans(Tween.TRANS_ELASTIC)
								"CUBIC": pt.set_trans(Tween.TRANS_CUBIC)
								"CIRC": pt.set_trans(Tween.TRANS_CIRC)
								"BOUNCE": pt.set_trans(Tween.TRANS_BOUNCE)
								"BACK": pt.set_trans(Tween.TRANS_BACK)
								"SPRING": pt.set_trans(Tween.TRANS_SPRING)
				twn.tween_subtween(sub)
			T_PROPERTIES:
				if twn:
					twn.tween_callback(func():
						for prop in step.props:
							var prop_info: Dictionary = step.props[prop]
							var result := _convert(node, prop, prop_info.vals)
							match prop_info.get(&"relative"):
								T_RELATIVE: node.set_indexed(prop, node.get_indexed(prop) + result)
								T_RELATIVE_NEG: node.set_indexed(prop, node.get_indexed(prop) - result)
								_: node.set_indexed(prop, result)
							)
				else:
					for prop in step.props:
						var prop_info: Dictionary = step.props[prop]
						var result := _convert(node, prop, prop_info.vals)
						match prop_info.get(&"relative"):
							T_RELATIVE: node.set_indexed(prop, node.get_indexed(prop) + result)
							T_RELATIVE_NEG: node.set_indexed(prop, node.get_indexed(prop) - result)
							_: node.set_indexed(prop, result)
	return twn

static func _tween(node: Node, tween_prop: Variant) -> Tween:
	if tween_prop is StringName:
		if node[tween_prop]: node[tween_prop].kill()
		node[tween_prop] = node.create_tween()
		return node[tween_prop]
	elif tween_prop is Tween:
		var twn: Tween = node.create_tween()
		(tween_prop as Tween).tween_subtween(twn)
		return twn
	return null

static func _convert(node: Node, prop: String, val: Array) -> Variant:
	var type := typeof(node.get_indexed(prop))
	var got: Variant
	match type:
		TYPE_VECTOR2, TYPE_VECTOR2I:
			got = Vector2(val[0], val[1])
		TYPE_VECTOR3, TYPE_VECTOR3I:
			got = Vector3(val[0], val[1], val[2])
		_:
			got = val[0]
	#prints("Converted %s:%s %s -> %s" % [prop, type_string(type), val, got])
	return got

static func _tokenize(src: String) -> PackedStringArray:
	var tokens := PackedStringArray()
	var lines := src.split("\n", false)
	var indent_stack := [0]
	for line in lines:
		if line.strip_edges().is_empty():
			continue
		var stripped := line.lstrip("\t")
		var indent := line.length() - stripped.length()
		if indent > indent_stack[-1]:
			indent_stack.append(indent)
			tokens.append(T_INDENT)
		elif indent < indent_stack[-1]:
			while indent < indent_stack[-1]:
				indent_stack.pop_back()
				tokens.append(T_DEDENT)
		var pattern := RegEx.new()
		pattern.compile(r'("[^"]*"|\d+\.\d+|\d+|[a-zA-Z_][\w\.]*|:|\+|\-)')
		var pos := 0
		while pos < stripped.length():
			var m := pattern.search(stripped, pos)
			if m == null: break
			tokens.append(m.get_string())
			pos = m.get_end()
		tokens.append(T_NEWLINE)
	while indent_stack.size() > 1:
		indent_stack.pop_back()
		tokens.append(T_DEDENT)
	return tokens

func _parse(tokens: PackedStringArray, i := 0) -> Array:
	var commands: Array = []

	while i < tokens.size():
		var t := tokens[i]

		# consume top-level newlines quickly
		if t == T_NEWLINE:
			i += 1
			continue

		# End of block
		if t == T_DEDENT:
			i += 1
			break
		
		if t == T_LOOP:
			commands.append({ type=T_LOOP, loop=0 })
			i += 1
			var args := []
			while i < tokens.size() and tokens[i] != T_NEWLINE:
				args.append(tokens[i])
				i += 1
			if args:
				commands[-1].loop = int(args[0])
			continue
		
		# block-like keywords with optional args (block, parallel, choice, on)
		if t in [ T_BLOCK, T_PARALLEL, T_CHOICE, T_ON ]:
			var keyword := t
			i += 1
			var args := []
			# collect tokens until colon (or we hit end)
			while i < tokens.size() and tokens[i] != T_COLON:
				if tokens[i] != T_NEWLINE:
					args.append(tokens[i])
				i += 1
			# skip colon if present
			if i < tokens.size() and tokens[i] == T_COLON:
				i += 1
			# skip NEWLINEs after colon
			while i < tokens.size() and tokens[i] == T_NEWLINE:
				i += 1
			# only parse nested block if there's an INDENT
			if i < tokens.size() and tokens[i] == T_INDENT:
				i += 1
				var block := { type=keyword, args=args }
				var got := _parse(tokens, i)
				block.children = got[0]
				commands.append(block)
				i = got[1]
				continue
			# no INDENT -> treat as empty block/attribute container
			commands.append({ type=keyword, args=args, children=[] })
			continue
		
		# Pause.
		if t == T_WAIT:
			commands.append({ type=T_WAIT, wait=default_pause_duration })
			i += 1
			continue
		
		# Pause (lone float)
		if t.is_valid_float():
			commands.append({ type=T_WAIT, wait=float(t) })
			i += 1
			continue
		
		# String event.
		if t.begins_with('"') and t.ends_with('"'):
			commands.append({ type=T_STRING, value=t.trim_prefix('"').trim_suffix('"') })
			i += 1
			continue
		
		# TODO: Warp
		if t == T_WARP:
			i += 1
			if i < tokens.size():
				commands.append({ type=T_WARP, expr=tokens[i] })
				i += 1
			continue
		
		# Tween step (mode + optional duration + props)
		if t in [ "L", "LINEAR", "E", "EASE", "EI", "EASEIN", "EO", "EASEOUT", "EOI", "EASEOUTIN" ] or\
			t.begins_with("E_") or t.begins_with("EASE_") or\
			t.begins_with("EI_") or t.begins_with("EASEIN_") or\
			t.begins_with("EO_") or t.begins_with("EASEOUT_") or\
			t.begins_with("EOI_") or t.begins_with("EASEOUTIN_"):
			var cmd := { type=T_PROPERTIES_TWEENED, mode=t, duration=default_tween_duration, props={} }
			i += 1
			# optional duration
			if i < tokens.size() and tokens[i].is_valid_float():
				cmd.duration = float(tokens[i])
				i += 1
			# parse properties (guaranteed to advance)
			var got := _parse_props(tokens, i)
			cmd.props = got[0]
			i = got[1]
			commands.append(cmd)
			continue

		# Standalone property line(s)
		# ensure token is a non-keyword identifier before calling _parse_props
		if _is_valid_property(t):
			var got := _parse_props(tokens, i)
			var cmd := { type=T_PROPERTIES, props=got[0] }
			i = got[1]
			commands.append(cmd)
			continue

		# fallback: consume one token to avoid infinite loops
		i += 1
	return [commands, i]

static func _parse_props(tokens: PackedStringArray, i: int) -> Array:
	var props := {}
	var start_i := i
	
	# loop until a structural token, keyword, or end
	while i < tokens.size():
		var token := tokens[i]
		# stop if we hit structural markers or keywords
		if token in [T_PARALLEL, T_CHOICE, T_BLOCK, T_ON, T_WARP, T_INDENT, T_DEDENT, T_NEWLINE, T_COLON ]:
			break

		# skip unknown / non-identifiers safely to guarantee progress
		if not _is_valid_property(token):
			i += 1
			continue

		# consume property name
		var vals := []
		var prop := { vals=vals }
		i += 1
		
		# gather values until next identifier/keyword/structure
		while i < tokens.size():
			var v := tokens[i]
			if v in [ T_PARALLEL, T_CHOICE, T_BLOCK, T_ON, T_WARP, T_INDENT, T_DEDENT, T_NEWLINE, T_COLON ] or _is_valid_property(v):
				break
			if v == T_RELATIVE:
				prop.relative = T_RELATIVE
			elif v == T_RELATIVE_NEG:
				prop.relative = T_RELATIVE_NEG
			# type conversions
			elif v.is_valid_float():
				vals.append(float(v))
			elif v.is_valid_int():
				vals.append(int(v))
			elif v == "true":
				vals.append(true)
			elif v == "false":
				vals.append(false)
			elif v.begins_with('"') and v.ends_with('"'):
				vals.append(v.trim_prefix('"').trim_suffix('"'))
			elif "." in v:
				var script := GDScript.new()
				script.source_code = "static func _return(): return %s" % v
				script.reload()
				var got: Variant = script._return()
				vals.append(got)
			else:
				# fallback string token
				vals.append(v)
			i += 1
		
		props[token.replace(".", ":")] = prop
	# safety net: if we didn't consume anything, advance to avoid infinite loop
	if i == start_i:
		i += 1
	return [props, i]

static func _is_valid_property(t: String) -> bool:
	if t != t.to_lower():
		return false
	if "." in t:
		return t.replace(".", "_").is_valid_unicode_identifier()
	return t.is_valid_unicode_identifier()
