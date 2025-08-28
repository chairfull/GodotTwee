# Twee v0.1 Early Dev Version
Requires `Godot 4.5+`

Inspired by [Ren'Py's transform system](https://www.renpy.org/doc/html/transforms.html) and built off [Godot's tween system](https://docs.godotengine.org/en/4.4/classes/class_tween.html).

Create tweens fast and easy.

```rpy
position (0, 0) modulate Color.WHITE
LINEAR position (100, 0) modulate lerp(Color.RED, Color.GREEN, randf())
LINEAR position (randf_range(-100, 100), 20.0) modulate Color.WHITE
```

Rig signal based animations in a snap.

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
	L 0.1 modulate Color.GREEN
	L 0.1 modulate Color.WHITE
	LOOP
```

# Basics

## Setting Properties
Write the name of a nodes properties, followed by the value to set. Multiple properties can share a line.

```rpy
position (0, 0)
modulate Color.RED
```

For relative properties, follow the name with a `+` or `-`

Here position is getting added, rotation subtracted, and modulate is absolute.

```rpy
position + (100, 100) rotation_degrees - 90 modulate Color.WHITE
```

## Animating Properties
Use `LINEAR` or `L` to animate a property linearly. Default duration is 1 second unless defined.

```rpy
position (0, 0)
LINEAR position (100, 0)
LINEAR position (100, 100)
LINEAR position (0, 100)
LINEAR 2 position (100, 0) 
```

Uses Godot's [transitions](https://docs.godotengine.org/en/4.4/classes/class_tween.html#enum-tween-transitiontype) and [easing](https://docs.godotengine.org/en/4.4/classes/class_tween.html#enum-tween-easetype).

- `LINEAR` or `L` constant speed. (`Tween.TRANS_LINEAR`)
- `EASE` or `E` starts off slow, ramps up, and ends slow. (`Tween.TRANS_SINE` & `Tween.EASE_IN_OUT`)
- `EASEIN` or `EI` starts fast, then slows. (`Tween.TRANS_SINE` & `Tween.EASE_IN`)
- `EASEOUT` or `EO` starts slow, then goes fast. (`Tween.TRANS_SINE` & `Tween.EASE_OUT`)
- `EASEINOUT` or `EIO` starts fast, then slows. (`Tween.TRANS_SINE` & `Tween.EASE_OUT_IN`)

These can follow an ease `EASE_` `E_` `EASEIN_` `EI_` `EASEOUT_` `EO_` `EASEOUTIN_` `EOI_`
- `QUNIT`
- `QUART`
- `QUAD`
- `EXPO`
- `ELASTIC`
- `CUBIC`
- `CIRC`
- `BOUNCE`
- `BACK`
- `SPRING`

## Relative Properties
To have a property change be relative to current use `+` or `-` after the name.

Here the object has a relative rotation but an absolute position animation.

```rpy
LINEAR 1.0 rotation_degrees + 90 position (0, 0)
LINEAR 1.0 rotation_degrees + 90 position (200, 0)
LINEAR 1.0 rotation_degrees + 90 position (200, 200)
LINEAR 1.0 rotation_degrees + 90 position (0, 200)
```

## Functions & Expressions
You can call built in functions or include expressions inside `()`.

```rpy
E rotation deg_to_rad(0)
E rotation deg_to_rad(90)
E rotation deg_to_rad(90 + 90)
E rotation deg_to_rad(90 * 3)
LOOP
```

## String Line
If your node has an `event` signal or method, you can emit it with `"strings"`

Edit `default_event_signal_or_method` to change.

```rpy
LINEAR 1.0 position (0, 0)
"At Top Left"
LINEAR 1.0 position (100, 100)
"Reached bottom right"
```

## Function Line
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

# Statements
Statements are in ALL CAPS so they don't clash with properties.

## ON
Connects to a signal in the node.
When a signal is emitted, other tweens will be ended/killed.

```rpy
ON mouse_entered:
	L modulate Color.YELLOW
ON mouse_exited:
	L modulate Color.WHITE
ON pressed:
	L modulate Color.TOMATO
```

## LOOP
Set number of loops. Leave blank for infinite.

```rpy
EASE 1 modulate Color.YELLOW
EASE 0.5 modulate Color.RED
LOOP
```

## BLOCK
Allows for more complex chaining.

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

## PARALLEL
Runs commands parallel to each other. Can write `PLL` for short.

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

## WAIT
Simply passing a float `1.0` is enough. Or you can type `WAIT`.

```rpy
L position (100, 100)

WAIT # Waits 1 second by default.

L position (0, 0)

2 # Wait 2 seconds.

L position (100, 0)
```

# Random Esoteric Features
- `rotation` will use `lerp_angle()` if no relative tokens (`+` `-`) are being used.

# To-Do
- Call functions.
- Set properties with variables.
- Better error handling.
- Allow comments.
- Allow addition of custom commands/blocks
	- Create better Parser class system.
