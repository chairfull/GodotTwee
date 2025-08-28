# Twee v0.1 Early Dev Version
Requires `Godot 4.5+`

Inspired by [Ren'Py's transform system](https://www.renpy.org/doc/html/transforms.html) and built off [Godot's tween system](https://docs.godotengine.org/en/4.4/classes/class_tween.html).

`Twee` is a scripting language for defining tweens fast & easy.

```rpy
position (0, 0) modulate Color.WHITE
EASE 1.0 position (100, 100) modulate Color.RED
```

It can access the node's methods/properties with the `@` prefix.

```rpy
position (0, 0)
BLOCK:
	EASE position @get_random_woodchop_point()
	REPEAT 3
gain_resource("wood", 1)
print("Got the wood! Let's go home.")
EASE position @get_dropoff_point()
```

It can be used to manage multiple signals at once.

```rpy
ON mouse_entered:
	L 0.2 modulate Color.YELLOW
	BLOCK:
		L 0.1 modulate Color.RED
		L 0.2 modulate Color.YELLOW
		LOOP

ON mouse_exited:
	L 0.2 modulate Color.WHITE

ON pressed:
	PARALLEL:
		L 0.1 modulate Color.GREEN
		L 0.1 modulate Color.WHITE
		LOOP
	PARALLEL:
		1.0
		get_tree().quit()
```

This animates an object to ease towards the mouse position every 1 second.

```rpy
E position @get_viewport().get_mouse_position()
LOOP
```

Here is a relative rotation.

```rpy
E rotation_degrees (@rotation_degrees + randf() * 15.0)
LOOP
```

# Getting Started
To set a property write it's name followed by the value. For `Vector2` and `Vector3` you don't need to write it all out.

```rpy
position (0, 0)
modulate Color.RED
```

They can share a line if you want.

```rpy
position (0, 0) modulate Color.WHITE rotation 90
```

Properties can be set with functions.

```rpy
position (randf() * 100, randf() * 100)
```

To access the nodes properties and functions use the `@` preface.

```rpy
modulate @random_color()
position (@cursor.x, @cursor.y)
```

# Animating
Use `LINEAR` or `L` to animate a property linearly. Default duration is 1 second unless defined.

```rpy
position (0, 0)
LINEAR position (100, 100)
```

Uses Godot's [transitions](https://docs.godotengine.org/en/4.4/classes/class_tween.html#enum-tween-transitiontype) and [easing](https://docs.godotengine.org/en/4.4/classes/class_tween.html#enum-tween-easetype).

- `LINEAR` or `L` constant speed. (`Tween.TRANS_LINEAR`)
- `EASE` or `E` starts off slow, ramps up, and ends slow. (`Tween.TRANS_SINE` & `Tween.EASE_IN_OUT`)
- `EASEIN` or `EI` starts fast, then slows. (`Tween.TRANS_SINE` & `Tween.EASE_IN`)
- `EASEOUT` or `EO` starts slow, then goes fast. (`Tween.TRANS_SINE` & `Tween.EASE_OUT`)
- `EASEINOUT` or `EIO` starts fast, then slows. (`Tween.TRANS_SINE` & `Tween.EASE_OUT_IN`)

```
Heads: EASE_ E_ EASEIN_ EI_ EASEOUT_ EO_ EASEOUTIN_ EOI_
Tails: QUNIT QUART QUAD EXPO ELASTIC CUBIC CIRC BOUNCE BACK SPRING
```

# Functions & Expressions
You can call built in functions or include expressions inside `()`.

```rpy
E rotation deg_to_rad(0)
E rotation deg_to_rad(90)
E rotation deg_to_rad(90 + 90)
E rotation deg_to_rad(90 * 3)
LOOP
```

# Function Line
You can have functions be called during the tween.

You can access the node with `node` or preface vars and funcs with `@`: `node.name` == `@name`

```rpy
E 1.0 modulate Color.RED
print("I, %s, am red!" % @name)
2.0

E 1.0 modulate Color.GREEN
print("Now %s is green!" % node.name)
2.0

E 1.0 modulate Color.WHITE
print("Back to how things should be.")
```

# Signals
To fire on a signal use the `ON` block.

You can define animations for many signals at once.
When a signal is emitted, other tweens defined in the `Twee` will be ended/killed.

```rpy
ON mouse_entered:
	L modulate Color.YELLOW
ON mouse_exited:
	L modulate Color.WHITE
ON pressed:
	L modulate Color.TOMATO
```

## Signal Arguments
Signal arguments can be accessed with the `~` preface.

Say we have a `signal choice_selected(index: int, message: String, color: Color)`

```rpy
ON choice_selected:
	E 0.1 modulate ~color
	print(~message)
	E modulate Color.TRANSPARENT
	selected.emit(~index)
```

# Looping
`LOOP` will cause animation to play over again infinitely unless you follow it with a number.

```rpy
EASE 1 modulate Color.YELLOW
EASE 0.5 modulate Color.RED
LOOP
```

# Complex Chains
`BLOCK` and `PARALLEL` allow for more complex animations.

# Blocks
A `BLOCK` is a sub-tween that pauses the parent tween until it is finished.

```rpy
# Walk to position.
LINEAR 1 position 0 0

# 3 time patrol.
BLOCK:
	LINEAR 1 position (100, 100)
	LINEAR 1 position (200, 100)
	REPEAT 3

# Back to home.
LINEAR 1 position (0, 0)
```

# Parallel Blocks
Use `PLL` or `PARALLEL` for blocks you want to run at the same time as their siblings.

```rpy
PARALLEL:
	LINEAR 1.0 rotation_degrees 0
	LINEAR 1.0 rotation_degrees 90
	LINEAR 1.0 rotation_degrees 180
	LINEAR 1.0 rotation_degrees 270
	LOOP
PARALLEL:
	LINEAR 0.3 modulate Color.RED
	LINEAR 0.1 modulate Color.WHITE
	LOOP
```

# Waiting
To wait for some seconds pass a float `1.0` by itself. Or you can type `WAIT`.

```rpy
L position (100, 100)

WAIT # Waits 1 second by default.

L position (0, 0)

2 # Wait 2 seconds.

L position (100, 0)
```

# Random Features
- `rotation` will use `lerp_angle()` if no relative tokens (`+` `-`) are being used.

# To-Do
- ~~Call functions.~~
- ~~Set properties with variables.~~
- ~~Signal arguments.~~
- For properties that will be animated, store thier original states and use `?` to access them. `E position ?position` will return to origin.
- Better error handling.
- Allow comments.
- Allow addition of custom commands/blocks
	- Create better Parser class system.
