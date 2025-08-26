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
const T_PARALLEL_SHORT := &"PLL"
const T_ON := &"ON"
const T_PROPERTIES_TWEENED := &"PROPS_TWEENED"
const T_PROPERTIES := &"PROPS"
const T_REL := &"+"
const T_REL_NEG := &"-"
const T_REL_RUNTIME := &"!"
const T_SPACE := &"SPACE"

const T_PASS := &"PASS" # TODO:
const T_CHOICE := &"CHOICE" # TODO:
const T_WARP := &"WARP" # TODO:

@export_custom(PROPERTY_HINT_EXPRESSION, "") var tween: String:
	set(t):
		tween = t
		changed.emit()

@export_group("Defaults", "default_")
@export var default_tween_duration := 1.0 ## Default seconds to tween if a duration wasn't explicitly given.
@export var default_pause_duration := 1.0 ## Default seconds to wait if WAIT wasn't explicitly given.
@export var default_event_signal_or_method := &"event" ## Will attempt to pass "string" events to this.
@export_storage var _script: GDScript
@export_storage var _method_count: int
var _properties: Dictionary[StringName, Dictionary]
@export_tool_button("Test") var test := func():
	var toks := _tokenize(tween)
	var pars := _parse(toks)
	print(toks)
	print(JSON.stringify(pars[0], "\t", false))
	#DisplayServer.clipboard_set(JSON.stringify(pars[0], "\t", false))

func get_property_type(node: Node, prop: StringName) -> int:
	if not prop in _properties:
		for p in node.get_property_list():
			if p.name == prop:
				_properties[prop] = p.type
				return p.type
	return _properties.get(prop, TYPE_NIL)

func run(node: Node, tween_prop: StringName):
	_properties = {}
	_script = GDScript.new()
	_script.source_code += "static var node: Node"
	_method_count = 0
	var steps: Array = _parse(_tokenize(tween))[0]
	_script.source_code += "\n# %s" % Time.get_unix_time_from_system()
	_script.source_code = _script.source_code.replace("@", "node.")
	#print(_script.source_code)
	_script.reload()
	_script.node = node
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
			"METH":
				if not twn:
					twn = _tween(node, tween_prop)
				twn.tween_callback(_eval.bind(step.meth))
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
					var pt: Tweener
					match prop_info.get(&"rel", T_REL_RUNTIME):
						T_REL:
							var result := _eval(prop_info.val)
							pt = sub.tween_property(node, prop, result, duration).as_relative()
						T_REL_NEG: 
							var result := _eval(prop_info.val)
							pt = sub.tween_property(node, prop, -result, duration).as_relative()
						T_REL_RUNTIME:
							var vars := {}
							vars[prop+"_a"] = node.get_indexed(prop)
							vars[prop+"_b"] = node.get_indexed(prop)
							sub.tween_callback(func():
								#print("update")
								var a := node.get_indexed(prop)
								var b := _eval(prop_info.val)
								vars[prop + "_a"] = a
								vars[prop + "_b"] = b if b != null else a)
							pt = sub.tween_method(func(t: float):
								var a: Variant = vars[prop + "_a"]
								var b: Variant = vars[prop + "_b"]
								#prints(prop, a, b)
								node.set_indexed(prop, lerp(a, b, t)), 0.0, 1.0, duration)
						_:
							var result := _eval(prop_info.val)
							if prop in ["rotation"]:
								pt = sub.tween_method(func(t: float): node.set_indexed(prop, lerp_angle(node.get_indexed(prop), result, t)), 0.0, 1.0, duration)
							else:
								pt = sub.tween_property(node, prop, result, duration)
					var mode: StringName = step.get(&"mode", &"LINEAR")
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
				if not twn:
					twn = _tween(node, tween_prop)
				twn.tween_callback(func():
					for prop in step.props:
						var prop_info: Dictionary = step.props[prop]
						var result := _eval(prop_info.val)
						match prop_info.get(&"rel"):
							T_REL: node.set_indexed(prop, node.get_indexed(prop) + result)
							T_REL: node.set_indexed(prop, node.get_indexed(prop) - result)
							_: node.set_indexed(prop, result)
						)
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
		var pattern := RegEx.create_from_string(r'("[^"]*"|\d+\.\d+|\d+|![a-zA-Z_]\w*(?:\(\))?|[a-zA-Z_]\w*(?:\.[a-zA-Z_]\w*)*\(?|[@()+\-*/%:,.])')
		var i := 0
		while i < stripped.length():
			var m := pattern.search(stripped, i)
			if m == null: break
			tokens.append(m.get_string())
			i = m.get_end()
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
		if t == T_NEWLINE or t == T_SPACE:
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
		if t in [ T_BLOCK, T_PARALLEL, T_PARALLEL_SHORT, T_CHOICE, T_ON ]:
			var keyword := t
			if t == T_PARALLEL_SHORT:
				keyword = T_PARALLEL
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
		if _is_wrapped(t):
			commands.append({ type=T_STRING, value=_unwrap(t) })
			i += 1
			continue
		
		if t.ends_with("("):
			i += 1
			var deep := 1
			var meth := t
			while i < tokens.size():
				meth += tokens[i]
				if tokens[i] == "(": deep += 1
				if tokens[i] == ")":
					deep -= 1
					if deep == 0:
						i += 1
						break
				i += 1
			commands.append({ type="METH", meth=_add_method(meth, false) })
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

func _parse_props(tokens: PackedStringArray, i: int) -> Array:
	var props := {}

	while i < tokens.size():
		var token := tokens[i]

		# stop on structural tokens
		if token in [T_PARALLEL, T_PARALLEL_SHORT, T_CHOICE, T_BLOCK, T_ON, T_WARP, T_INDENT, T_DEDENT, T_NEWLINE, T_COLON, T_LOOP]:
			break

		# property must be a valid identifier like "modulate" or "position.x"
		if not _is_valid_property(token):
			i += 1
			continue

		var prop := { val="" }
		var name := token.replace(".", ":")
		i += 1

		# optional runtime marker
		var runtime_eval := false
		if i < tokens.size() and tokens[i] == "!":
			runtime_eval = true
			prop.rel = T_REL_RUNTIME
			i += 1

		# collect expression tokens
		var expr_tokens := []
		var paren_level := 0
		while i < tokens.size():
			var v := tokens[i]

			if v.ends_with("("):
				paren_level += 1
			elif v == ")":
				paren_level -= 1

			# break if top-level property/structural token and no open parens
			if paren_level == 0 and (v in [T_NEWLINE, T_DEDENT, T_COLON] or _is_valid_property(v)):
				break

			expr_tokens.append(v)
			i += 1

		if expr_tokens.size() > 0:
			var expr := "".join(expr_tokens)
			expr = _maybe_wrap_vector(expr)
			prop.val = _add_method(expr)

		props[name] = prop

	return [props, i]

func _maybe_wrap_vector(expr: String) -> String:
	# trim whitespace
	expr = expr.strip_edges()
	if expr.begins_with("(") and expr.ends_with(")"):
		var inner := expr.substr(1, expr.length() - 2)
		# count top-level commas
		var depth := 0
		var commas := 0
		for c in inner:
			if c == "(": depth += 1
			elif c == ")": depth -= 1
			elif c == "," and depth == 0: commas += 1
		if commas == 1: return "Vector2%s" % expr
		elif commas == 2: return "Vector3%s" % expr
		elif commas == 3: return "Color%s" % expr
	return expr

static func _is_wrapped(t: String, head := '"', tail := '"') -> bool:
	return t.begins_with(head) and t.ends_with(tail)

static func _is_valid_property(t: String) -> bool:
	if "(" in t:
		return true
	if t != t.to_lower():
		return false
	if "." in t:
		return t.replace(".", "_").is_valid_unicode_identifier()
	return t.is_valid_unicode_identifier()

static func _unwrap(s: String, head := '"', tail := '"') -> String:
	return s.trim_prefix(head).trim_suffix(tail)

func _add_method(expr: String, returns := true) -> StringName:
	var method_name := "_m%s" % _method_count
	if returns:
		_script.source_code += "\nstatic func %s(): return %s" % [method_name, expr]
	else:
		_script.source_code += "\nstatic func %s(): %s" % [method_name, expr]
	_method_count += 1
	return method_name
	
func _eval(method_name: String) -> Variant:
	return _script.call(method_name)
