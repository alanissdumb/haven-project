extends Area2D

const MAX_HP = 15
const SPEED = 240.0
const STEER = 400.0
const SHOT_EVERY = 2.4
const SHOT_TELL = 0.5          # its core charges up this long before it fires
const SHOT_SPEED = 380.0
const CONTACT_KNOCK = 800.0
const ORB = preload("res://levels/final_boss/spiral_orb.tscn")
const HIT_FX = preload("res://levels/final_boss/hit_fx.tscn")

var hp = MAX_HP
var vel = Vector2.ZERO
var shot_cd = 0.0
var flash = 0.0
var age = 0.0
var k = 1.0           # size factor from the camera zoom
var wobble = 0.0

func _ready():
	add_to_group("minion")
	var cam = get_viewport().get_camera_2d()
	if cam:
		k = sqrt(1.0 / cam.zoom.x)
	scale = Vector2.ONE * k
	shot_cd = randf_range(1.2, SHOT_EVERY)
	wobble = randf() * TAU

func _physics_process(delta):
	age += delta
	var player = get_tree().get_first_node_in_group("player")
	if player == null or player.dead:
		return

	# Keep a medium distance from the player, circling round
	var to_p = player.global_position - global_position
	var dist = to_p.length()
	var dir = to_p.normalized()
	var keep = 420.0 * k
	var desired = Vector2.ZERO
	if dist > keep * 1.2:
		desired = dir * SPEED
	elif dist < keep * 0.8:
		desired = -dir * SPEED
	else:
		desired = dir.orthogonal() * SPEED * 0.6 * sign(sin(age * 0.5 + wobble))
	vel = vel.move_toward(desired, STEER * delta)
	position += vel * delta

	# Light attack: one slow aimed orb every couple of seconds
	shot_cd -= delta
	if shot_cd <= 0.0:
		fire(dir)
		shot_cd = SHOT_EVERY + randf_range(-0.4, 0.6)

	# Contact: 1 heart of damage and a shove
	for body in get_overlapping_bodies():
		if body.has_method("can_be_hit") and body.can_be_hit():
			body.take_damage(1)
			var push = (body.global_position - global_position).normalized()
			body.knockback(push * CONTACT_KNOCK * k)
			vel = -push * 200.0

func fire(dir):
	var orb = ORB.instantiate()
	orb.global_position = global_position
	orb.velocity = dir * SHOT_SPEED
	orb.color = Color(1.0, 0.35, 0.5)
	orb.scale = Vector2.ONE * k
	get_parent().add_child(orb)

func take_damage(amount):
	hp -= amount
	flash = 1.0
	if hp <= 0:
		var fx = HIT_FX.instantiate()
		fx.global_position = global_position
		fx.big = true
		fx.color = Color(1.0, 0.4, 0.6)
		get_parent().add_child(fx)
		queue_free()

func _process(delta):
	flash = move_toward(flash, 0.0, delta * 6.0)
	queue_redraw()

func _draw():
	var tell = 0.0
	if shot_cd < SHOT_TELL:
		tell = clamp(1.0 - shot_cd / SHOT_TELL, 0.0, 1.0)

	draw_circle(Vector2.ZERO, 34.0, Color(0.55, 0.15, 0.3).lerp(Color.WHITE, flash * 0.7))
	draw_arc(Vector2.ZERO, 34.0, 0, TAU, 32, Color(1.0, 0.5, 0.6), 3.0)
	draw_circle(Vector2.ZERO, 12.0 + 6.0 * tell, Color(1.0, 0.8, 0.5).lerp(Color.WHITE, tell))
	for i in range(3):
		var a = age * 2.0 + i * TAU / 3.0
		draw_circle(Vector2.RIGHT.rotated(a) * 46.0, 6.0, Color(1.0, 0.5, 0.6))

	# Little health bar above it
	var w = 60.0
	draw_rect(Rect2(-w / 2.0, -62, w, 8), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(-w / 2.0, -62, w * hp / float(MAX_HP), 8), Color(1.0, 0.3, 0.4))
