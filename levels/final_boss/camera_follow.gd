extends Camera2D

const FOLLOW_SPEED = 5.0

var follow = false         # the boss switches this on for the black hole phase
var arena = Rect2()        # the camera never shows anything outside this

func _process(delta):
	if not follow:
		return
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var target = player.global_position
	var half = get_viewport_rect().size / zoom / 2.0
	var lo = arena.position + half
	var hi = arena.end - half
	# if the arena is smaller than the screen on an axis, centre on it instead
	target.x = clamp(target.x, lo.x, hi.x) if lo.x <= hi.x else arena.get_center().x
	target.y = clamp(target.y, lo.y, hi.y) if lo.y <= hi.y else arena.get_center().y

	global_position = global_position.lerp(target, 1.0 - exp(-FOLLOW_SPEED * delta))
