extends Node2D

const ARMS = 5
const LENGTH = 4500.0
const WIDTH = 95.0
const WARN_TIME = 0.8
const ACTIVE_TIME = 6.0
const TURN_SPEED = 0.25      # radians per second
const REVERSE_PAUSE = 0.5    # arms freeze and flash, then spin the other way

const PX_SCALE = 5.0        # bh_ult_beam is ~20 art px thick -> 100 px over the 95 px hitbox

var timer = 0.0
var angle = 0.0
var dir = 1.0
var reversed = false
var pause_left = 0.0
var arms = []
var origin = null

func _ready():
	angle = randf() * TAU
	dir = [-1.0, 1.0].pick_random()
	make_arms()

func _physics_process(delta):
	timer += delta
	if timer >= WARN_TIME:
		if pause_left > 0.0:
			pause_left -= delta
		else:
			angle += TURN_SPEED * dir * delta
		if not reversed and timer >= WARN_TIME + ACTIVE_TIME / 2.0:
			reversed = true
			dir = -dir
			pause_left = REVERSE_PAUSE
		check_hit()
	if timer >= WARN_TIME + ACTIVE_TIME:
		queue_free()

func check_hit():
	var player = get_tree().get_first_node_in_group("player")
	if not player or not player.can_be_hit():
		return
	var p = player.global_position - global_position
	for k in range(ARMS):
		var d = Vector2.RIGHT.rotated(angle + k * TAU / ARMS)
		var along = p.dot(d)
		var across = abs(p.cross(d))
		if along > 0.0 and along < LENGTH and across < WIDTH / 2.0 + 14.0:
			player.take_damage(1)
			return

func make_arms():
	for k in range(ARMS):
		var pivot = Node2D.new()
		add_child(pivot)
		var warn = FX.strip("bh_grid_warning", pivot, LENGTH, PX_SCALE)
		var beam = FX.strip("bh_ult_beam", pivot, LENGTH, PX_SCALE)
		beam.hide()
		arms.append({"pivot": pivot, "warn": warn, "beam": beam})
	origin = FX.spawn("bh_ult_beam_origin", self, Vector2.ZERO, 0, PX_SCALE)
	origin.hide()

func _process(_delta):
	var active = timer >= WARN_TIME
	var frozen = pause_left > 0.0
	origin.visible = active
	for k in range(ARMS):
		var arm = arms[k]
		arm.pivot.rotation = angle + k * TAU / ARMS
		arm.warn.visible = not active
		arm.beam.visible = active
		# yellow flash: about to reverse
		arm.beam.modulate = Color(1, 0.9, 0.5) if frozen else Color.WHITE
