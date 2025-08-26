# Tweeny v0.1 Early Dev Version
Requires `Godot 4.5+`

Inspired by [Ren'Py's transform system](https://www.renpy.org/doc/html/transforms.html) and built off [Godots tween system](https://docs.godotengine.org/en/4.4/classes/class_tween.html).

Create tweens fast and easy.

```rpy
position 0 0 modulate Color.WHITE
LINEAR position 0.0 100.0 modulate Color.RED
LINEAR position 100.0 100.0 modulate Color.WHITE
LINEAR position 100.0 0.0 modulate Color.RED
LINEAR position 0.0 0.0 modulate Color.WHITE
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
position 0 0
modulate Color.RED
```

For relative properties, follow the name with a `+` or `-`

Here position is getting added, rotation subtracted, and modulate is absolute.

```rpy
position + 100 100 rotation_degrees - 90 modulate Color.WHITE
```

## Animating Properties
Use `LINEAR` or `L` to animate a property linearly. Default duration is 1 second unless defined.

```rpy
position 0 0
LINEAR position 100 0
LINEAR position 100 100
LINEAR position 0 100
LINEAR 2 position 100 0 
```

Uses Godots built in [transitions](https://docs.godotengine.org/en/4.4/classes/class_tween.html#enum-tween-transitiontype) and [easing](https://docs.godotengine.org/en/4.4/classes/class_tween.html#enum-tween-easetype).

- `LINEAR` or `L` constant speed. (`Tween.TRANS_LINEAR`)
- `EASE` or `E` starts off slow, ramps up, and ends slow. (`Tween.TRANS_SINE` + `Tween.EASE_IN_OUT`)
- `EASEIN` or `EI` starts fast, then slows. (`Tween.TRANS_SIZE` + `Tween.EASE_IN`)
- `EASEOUT` or `EO` starts slow, then goes fast. (`Tween.TRANS_SIZE` + `Tween.EASE_OUT`)
- `EASEINOUT` or `EIO` starts fast, then slows. (`Tween.TRANS_SIZE` + `Tween.EASE_OUT_IN`)

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
LINEAR 1.0 rotation_degrees + 90 position 0 0
LINEAR 1.0 rotation_degrees + 90 position 200 0
LINEAR 1.0 rotation_degrees + 90 position 200 200
LINEAR 1.0 rotation_degrees + 90 position 0 200
```

## Event Message
If your node has an `event` signal, you can emit it with `"strings"`

```rpy
LINEAR 1.0 position 0 0
"At Top Left"
LINEAR 1.0 position 100 100
"Reached bottom right"
```

# Statements
Statements are in ALL CAPS so they don't clash with properties.

## ON
Connects to a signal in the node.

```rpy
ON mouse_entered:
	LINEAR 1.0 modulate Color.YELLOW
ON mouse_exited:
	LINEAR 1.0 modulate Color.WHITE
ON pressed:
	LINEAR 1.0 modulate Color.TOMATO
```

## LOOP
Set number of loops. 0 = infinite.

```rpy
LINEAR 1 modulate Color.YELLOW
LINEAR 0.5 modulate Color.RED
LOOP
```

## BLOCK
Allows for more complex chaining.

- Walks to position.
- Marches back and forth 3 times.
- Marches back to origin.

```rpy
LINEAR 1 position 0 0
BLOCK:
	LINEAR 1 position 100 100
	LINEAR 1 position 200 100
	REPEAT 3
LINEAR 1 position 0 0
```

## PARALLEL
Runs commands parallel to each other.

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

## TIME
Simply passing a float `1.0` is enough. Or you can type `TIME`

```rpy
LINEAR 1 position 100 100

TIME # Wait 1 second.

LINEAR 1 position 0 0

2 # Wait 2 seconds.

LINEAR 1 position 100 0
```

# To-Do
- Call functions.
- Set properties with variables.
- Better error handling.
- Allow comments.
