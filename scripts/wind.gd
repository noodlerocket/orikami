class_name Wind
extends RefCounted
## The wind over Kamiyo. There is ONE wind, shared by everything: lanterns,
## shop curtains, banners, grass, blossom, the rain, and the Ronin's cloak
## all ask this script how hard it is blowing where they are.
##
## The wind is a steady breeze plus gusts. A gust is a wave that rolls along
## the street in the direction the wind blows, so you can watch it arrive:
## the far lantern swings first, then the curtain, then his cloak.
##
## Tune it from the Village node (the "Wind" group in the Inspector).

## The steady breeze, in metres per second.
static var breeze := 2.0
## How much stronger a full gust is than the breeze.
static var gusts := 4.5
## Which way it blows. (-1, 0, 0) is toward the left of the screen, the same
## way the rain slants.
static var direction := Vector3(-1.0, 0.0, 0.0)
## How fast gust fronts travel, and how long they are.
static var gust_speed := 1.0
static var gust_length := 0.09


## A clock that keeps running during hit-stop, so the wind never freezes.
static func now() -> float:
	return Time.get_ticks_msec() * 0.001


## How fast the wind is blowing at position x along the street, right now.
static func speed_at(x: float) -> float:
	var t := now()
	var roll := x * gust_length + t * gust_speed
	var swell := 0.5 + 0.5 * sin(roll)
	var ripple := 0.5 + 0.5 * sin(roll * 2.3 + 1.7 + sin(t * 0.21) * 2.0)
	return breeze + gusts * swell * swell * (0.55 + 0.45 * ripple)


## The wind at x as a direction and speed.
static func at(x: float) -> Vector3:
	return direction * speed_at(x)
