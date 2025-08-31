@tool
class_name Twee extends Resource

const Tokenizer := preload("twee_tokenizer.gd")
const Token := preload("twee_tokens.gd")
const Parser := preload("twee_parser.gd")
const ClassWriter := preload("twee_class_writer.gd")

@export_custom(PROPERTY_HINT_EXPRESSION, "") var code: String:
	set(t):
		code = t
		changed.emit()

@export_group("Defaults", "default_")
#const default_tween_duration := 1.0 ## Default seconds to tween if a duration wasn't explicitly given.
#const default_pause_duration := 1.0 ## Default seconds to wait if WAIT wasn't explicitly given.
#const default_event_signal_or_method := &"event" ## Will attempt to pass "string" events to this.
var _properties: Dictionary[StringName, Dictionary]
@export_tool_button("Test") var test := func():
	var toks := Tokenizer.tokenize(code)
	var pars := Parser.parse(toks)
	print(toks)
	print(JSON.stringify(pars, "\t", false))
	#DisplayServer.clipboard_set(JSON.stringify(pars[0], "\t", false))

func get_property_type(node: Node, prop: StringName) -> int:
	if not prop in _properties:
		for p in node.get_property_list():
			if p.name == prop:
				_properties[prop] = p.type
				return p.type
	return _properties.get(prop, TYPE_NIL)

#region Access Tween

func _get_meta_key(node: Node) -> StringName:
	# For debug purposes, we'll use node id and resource id to create a meta key.
	# Resource instance id's are negative, and meta fields can't take a "-", so we remove it.
	var tween_prop := StringName("twee_%s_%s" % [node.get_instance_id(), str(get_instance_id()).substr(1)])
	#print("TWEEN PROP ", node, tween_prop)
	return tween_prop

func get_tween(node: Node) -> Tween:
	var mk := _get_meta_key(node)
	if node.has_meta(mk):
		return node.get_meta(mk)
	return null

func is_running(node: Node) -> bool:
	var twn := get_tween(node)
	return twn and twn.is_running()

func kill(node: Node):
	var mk := _get_meta_key(node)
	if node.has_meta(mk):
		node.get_meta(mk).kill()
		node.set_meta(mk, null)

func play(node: Node):
	var twn := get_tween(node)
	if twn: twn.play()

func pause(node: Node):
	var twn := get_tween(node)
	if twn: twn.pause()

#endregion

func reload(node: Node):
	if not code.strip_edges():
		push_warning("Code was empty.")
		return
	
	var tween_prop := _get_meta_key(node)
	_properties = {}
	
	var toks := Tokenizer.tokenize(code)
	var pars := Parser.parse(toks)
	var print_source := true
	ClassWriter.start()
	var twn := _create_tween(node, tween_prop, pars, node)
	var scr := ClassWriter.finish({ node=node }, print_source)
	for prop in Parser.all_props:
		scr.initial_state[prop] = node.get_indexed(prop)
	set_twee_script(node, scr)
	print(scr.initial_state)
	return twn

func set_twee_script(node: Node, script: GDScript):
	var id := "tweescript_%s_%s" % [node.get_instance_id(), abs(get_instance_id())]
	node.set_meta(id, script)

func get_twee_script(node: Node) -> GDScript:
	var id := "tweescript_%s_%s" % [node.get_instance_id(), abs(get_instance_id())]
	return node.get_meta(id)

static func prnt_tokens(cd: String):
	var toks := Tokenizer.tokenize(cd)
	print(toks)

static func prnt_parsed(cd: String):
	var toks := Tokenizer.tokenize(cd)
	var pars := Parser.parse(toks)
	print(JSON.stringify(pars, "\t", false))

#static func prnt_source_code(cd: String):
	#var toks := Tokenizer.tokenize(cd)
	#var pars := Parser.parse(toks)
	#ClassWriter.start()
	#var script_class := ClassWriter.finish({}, true)

func _create_tween(node: Node, tween_prop: Variant, steps: Array[Dictionary], parent: Node, subnode_uid: String = "") -> Tween:
	var twn: Tween = null
	for step in steps:
		match step.type:
			Token.FOR:
				match step.args[0]:
					Token.CHILD:
						for subnode in node.get_children():
							var uid := ClassWriter.add_subnode(subnode)
							_create_tween(subnode, "", step.children, node, uid)
					Token.GROUP:
						for subnode in node.get_tree().get_nodes_in_group(step.args[1]):
							var uid := ClassWriter.add_subnode(subnode)
							_create_tween(subnode, "", step.children, node, uid)
					Token.PROP:
						for subnode in node[step.args[1]]:
							if subnode:
								var uid := ClassWriter.add_subnode(subnode)
								_create_tween(subnode, "", step.children, node, uid)
					Token.FIND:
						for subnode in node.find_children(step.args[1], step.args[2]):
							var uid := ClassWriter.add_subnode(subnode)
							_create_tween(subnode, "", step.children, node, uid)
			Token.ON:
				for signal_id in step.args:
					node[signal_id].connect(func(...args):
						var sig_info := get_signal_info(node, signal_id)
						for i in args.size():
							if i < sig_info.args.size():
								var arg_info = sig_info.args[i]
								get_twee_script(parent).signal_args[arg_info.name] = args[i]
								
						_create_tween(node, tween_prop, step.children, node))
			Token.PARALLEL:
				if not twn:
					twn = _tween(node, tween_prop)
				twn.set_parallel()
				_create_tween(node, twn, step.children, node)
			Token.BLOCK:
				if not twn:
					twn = _tween(node, tween_prop)
				_create_tween(node, twn, step.children, node)
			"METH":
				if not twn:
					twn = _tween(node, tween_prop)
				twn.tween_callback(get_twee_script(parent).call.bind(step.meth))
			Token.LOOP:
				if twn:
					twn.set_loops(step.loop)
				else:
					push_error("No tween to repeat.")
			Token.WAIT:
				if not twn:
					twn = _tween(node, tween_prop)
				twn.tween_interval(step.wait)
			Token.STRING:
				# Call signal.
				if parent.has_signal(&"_event"):
					if not twn:
						twn = _tween(node, tween_prop)
					twn.tween_callback(parent[&"_event"].emit.bind(step.value))
				# Call method.
				elif parent.has_method(&"_event"):
					if not twn:
						twn = _tween(node, tween_prop)
					twn.tween_callback(parent[&"_event"].bind(step.value))
				else:
					push_warning("No event signal to emit.")
			Token.PROPERTIES_TWEENED:
				# Store initial state.
				#for prop in step.props:
					#script_class.initial_state[prop] = node.get_indexed(prop)
				if not twn: twn = _tween(node, tween_prop)
				var duration: float = step.duration
				var sub := node.create_tween()
				sub.set_parallel()
				for prop in step.props:
					var prop_info: Dictionary = step.props[prop]
					var pt: Tweener
					var vars := {}
					var op := get_object_and_property(node, prop)
					var true_object: Object = op[0]
					var true_prop: String = op[1]
					vars[prop + "_a"] = true_object.get_indexed(true_prop)
					vars[prop + "_b"] = true_object.get_indexed(true_prop)
					var call_name := ClassWriter.add_static_func(prop_info.val.replace("@", "node."))
					sub.tween_callback(func():
						var a := true_object.get_indexed(true_prop)
						var b := get_twee_script(parent).call(call_name)
						vars[prop + "_a"] = a
						vars[prop + "_b"] = b if b != null else a)
					pt = sub.tween_method(func(t: float):
						var a: Variant = vars[prop + "_a"]
						var b: Variant = vars[prop + "_b"]
						true_object.set_indexed(true_prop, lerp(a, type_convert(b, typeof(a)), t)), 0.0, 1.0, duration)
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
			Token.PROPERTIES:
				# Store initial state.
				#for prop in step.props:
					#script_class.initial_state[prop] = node.get_indexed(prop)
				if not twn:
					twn = _tween(node, tween_prop)
				twn.tween_callback(func():
					for prop in step.props:
						var prop_info: Dictionary = step.props[prop]
						var op := get_object_and_property(node, prop)
						var true_object: Object = op[0]
						var true_prop: String = op[1]
						var result: Variant = get_twee_script(parent)[prop_info.val].call()
						true_object.set_indexed(true_prop, result)
						)
	return twn

static func get_object_and_property(node: Node, prop: String) -> Array:
	var node_and_resource := node.get_node_and_resource(prop)
	var n: Node = node_and_resource[0]
	var r: Resource = node_and_resource[1]
	var p: NodePath = node_and_resource[2]
	return [r if r else n if n else node, p if p else prop]

static func get_signal_info(node: Node, signame: StringName) -> Dictionary:
	for sig in node.get_signal_list():
		if sig.name == signame:
			return sig
	return {}

static func _tween(node: Node, tween_prop: Variant) -> Tween:
	if tween_prop is StringName:
		if node.has_meta(tween_prop):
			node.get_meta(tween_prop).kill()
		var twn := node.create_tween()
		node.set_meta(tween_prop, twn)
		twn.finished.connect(node.set_meta.bind(tween_prop, null))
		return twn
	elif tween_prop is Tween:
		var twn: Tween = node.create_tween()
		(tween_prop as Tween).tween_subtween(twn)
		return twn
	return null
