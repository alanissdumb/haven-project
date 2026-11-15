extends CharacterBody2D

const SPEED = 400.0
const ACCELERATION = 2000.0
const FRICTION = 1500.0
const TURN_SPEED = 10.0
const BULLET = preload("res://levels/miniboss_2/bullet.tscn")
const FIRE_DELAY = 0.2
const DASH_DISTANCE = 220.0
const DASH_IFRAMES = 0.35
const DASH_COOLDOWN = 2.0
const MAX_HP = 4

# Powerups
const BUFF_TIME = 10.0
const SUPER_TIME = 12.0
const BUFF_NAMES = {
	"rapid": "Rapid Fire",
	"dash": "No Dash Cooldown",
	"double": "Double Shot",
	"speed": "Speed Boost",
	"super": "OVERCHARGE",
}

# Soft barrier (distances are in screen pixels, so they look the same at any zoom)
const EDGE_MARGIN = 30.0    # the hard limit sits this far inside the screen edge
const SOFT_ZONE = 110.0     # the push-back starts this far inside the hard limit
const BARRIER_PUSH = 1400.0

var hp = 4
var invincible = false
var pull = Vector2.ZERO
var facing = Vector2.UP
var cooldown = 0.0
var dashing = false
var dash_cd = 0.0
var dead = false
var boom = 0.0

var stage_speed = 1.0       # the boss sets this to 1.5 when the black hole appears
var buffs = {}              # name -> seconds left
var shield_time = 0.0
var shield_on = false
var toast = ""
var toast_time = 0.0

func _ready():
	add_to_group("player")
	$Explosion.z_index = 10
	$Explosion.draw.connect(_draw_explosion)
	$CanvasLayer/DashBar.max_value = DASH_COOLDOWN

	$CanvasLayer/Hearts.add_theme_constant_override("separation", 6)
	for heart in $CanvasLayer/Hearts.get_children():
		heart.color = Color(0, 0, 0, 0)   # hides the square
		heart.draw.connect(draw_heart.bind(heart))
		heart.queue_redraw()

# ---------- Health ----------

func take_damage(amount):
	if dead or invincible or dashing or shield_time > 0.0:
		return
	hp -= amount
	update_hearts()

	if hp <= 0:
		die()
		return

	invincible = true
	$Ship.modulate = Color(1, 1, 1, 0.4)
	await get_tree().create_timer(1.0).timeout
	invincible = false
	$Ship.modulate = Color.WHITE

func can_be_hit():
	return not (dead or invincible or dashing or shield_time > 0.0)

func update_hearts():
	var i = 0
	for heart in $CanvasLayer/Hearts.get_children():
		heart.set_meta("full", i < hp)
		heart.queue_redraw()
		i += 1

func draw_heart(heart):
	var s = min(heart.size.x, heart.size.y)
	var pts = PackedVector2Array()
	for i in range(40):
		var t = i * TAU / 40.0
		var x = 16.0 * pow(sin(t), 3)
		var y = -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		pts.append(Vector2(x, y - 2.5) * (s / 32.0) + Vector2(s, s) / 2.0)

	if heart.get_meta("full", true):
		heart.draw_colored_polygon(pts, Color(1.0, 0.15, 0.3))
	var outline = pts.duplicate()
	outline.append(pts[0])
	heart.draw_polyline(outline, Color(0.45, 0.0, 0.1), 2.0)

# ---------- Powerups ----------

func apply_powerup(kind):
	match kind:
		"health":
			hp = min(hp + 1, MAX_HP)
			update_hearts()
			show_toast("+1 Health")
		"rapid":
			buffs["rapid"] = BUFF_TIME
			show_toast("Rapid Fire!")
		"dash":
			buffs["dash"] = BUFF_TIME
			dash_cd = 0.0
			show_toast("No Dash Cooldown!")
		"double":
			buffs["double"] = BUFF_TIME
			show_toast("Double Shot!")
		"speed":
			buffs["speed"] = BUFF_TIME
			show_toast("Speed Boost!")
		"super":
			buffs["super"] = SUPER_TIME
			shield_time = 2.0
			show_toast("OVERCHARGE!")

func show_toast(text):
	toast = text
	toast_time = 2.0

func tick_buffs(delta):
	for key in buffs.keys():
		buffs[key] -= delta
		if buffs[key] <= 0.0:
			buffs.erase(key)
	shield_time = max(shield_time - delta, 0.0)
	toast_time = max(toast_time - delta, 0.0)

	if shield_time > 0.0:
		$Ship.modulate = Color(1.0, 0.9, 0.4, 0.6 + 0.3 * sin(Time.get_ticks_msec() * 0.03))
		shield_on = true
	elif shield_on:
		shield_on = false
		$Ship.modulate = Color.WHITE
	update_buff_label()

func update_buff_label():
	var lines = []
	if toast_time > 0.0:
		lines.append(toast)
	for key in buffs.keys():
		lines.append("%s  %.1f" % [BUFF_NAMES[key], buffs[key]])
	if shield_time > 0.0:
		lines.append("Shield  %.1f" % shield_time)
	$CanvasLayer/BuffLabel.text = "\n".join(lines)

func speed_mult():
	var m = stage_speed
	if buffs.has("speed") or buffs.has("super"):
		m *= 1.4
	return m

func fire_delay():
	var d = FIRE_DELAY
	if buffs.has("rapid"):
		d *= 0.5
	if buffs.has("super"):
		d *= 0.7
	return d

# ---------- Movement ----------

func _physics_process(delta):
	if dead:
		return
	dash_cd = max(dash_cd - delta, 0.0)
	tick_buffs(delta)

	var bar = $CanvasLayer/DashBar
	bar.value = DASH_COOLDOWN - dash_cd
	bar.modulate = Color(0.5, 0.9, 1.0) if dash_cd <= 0.0 else Color(1, 1, 1, 0.6)

	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var m = speed_mult()

	# Smooth movement
	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(direction * SPEED * m, ACCELERATION * m * delta)
		facing = direction.normalized()
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * m * delta)

	# Gravity and the arena barrier push on top of your own movement
	var base_velocity = velocity
	velocity += pull + barrier_push()
	move_and_slide()
	velocity = base_velocity
	pull = Vector2.ZERO
	clamp_to_arena()

	# Smooth turning
	if direction != Vector2.ZERO:
		var target = facing.angle() + PI / 2
		$Ship.rotation = lerp_angle($Ship.rotation, target, TURN_SPEED * delta)
	$Ship.thrust = engine_thrust(direction)

	cooldown -= delta
	if Input.is_action_pressed("ui_accept") and cooldown <= 0:
		shoot()
		cooldown = fire_delay()

func shoot():
	var aim = Vector2.UP.rotated($Ship.rotation)
	var side = aim.orthogonal()
	var offsets = [0.0]
	if buffs.has("double"):
		offsets = [-14.0, 14.0]

	for o in offsets:
		var bullet = BULLET.instantiate()
		bullet.global_position = global_position + aim * 40 + side * o
		bullet.direction = aim
		bullet.rotation = aim.angle()
		if buffs.has("super"):
			bullet.damage = 2
		get_parent().add_child(bullet)

# ---------- Arena ----------

func get_view_rect():
	var cam = get_viewport().get_camera_2d()
	if cam:
		var size = get_viewport_rect().size / cam.zoom
		return Rect2(cam.get_screen_center_position() - size / 2.0, size)
	return get_viewport_rect()

func arena_rect():
	var cam = get_viewport().get_camera_2d()
	var z = cam.zoom.x if cam else 1.0
	return get_view_rect().grow(-EDGE_MARGIN / z)

func barrier_push():
	var cam = get_viewport().get_camera_2d()
	var z = cam.zoom.x if cam else 1.0
	var soft = SOFT_ZONE / z
	var inner = arena_rect().grow(-soft)
	var push = Vector2.ZERO
	if global_position.x < inner.position.x:
		push.x = (inner.position.x - global_position.x) / soft
	elif global_position.x > inner.end.x:
		push.x = -(global_position.x - inner.end.x) / soft
	if global_position.y < inner.position.y:
		push.y = (inner.position.y - global_position.y) / soft
	elif global_position.y > inner.end.y:
		push.y = -(global_position.y - inner.end.y) / soft
	return push * BARRIER_PUSH

func clamp_to_arena():
	var arena = arena_rect()
	global_position = global_position.clamp(arena.position, arena.end)

# ---------- Dash ----------

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SHIFT:
		try_dash()

# Engine flame: big while dashing or speed boosted, small while moving
func engine_thrust(direction):
	if dashing or buffs.has("speed") or buffs.has("super"):
		return $Ship.THRUST_BIG
	if direction != Vector2.ZERO:
		return $Ship.THRUST_SMALL
	return $Ship.THRUST_OFF

func try_dash():
	if dead or dashing or dash_cd > 0.0:
		return

	var dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dir == Vector2.ZERO:
		dir = Vector2.UP.rotated($Ship.rotation)  # dash where the nose points
	dir = dir.normalized()

	dash_cd = 0.0 if buffs.has("dash") else DASH_COOLDOWN
	dashing = true
	$Ship.thrust = $Ship.THRUST_BIG   # so the dash ghost leaves the big flame too
	spawn_ghost()

	var arena = arena_rect()
	global_position = (global_position + dir * DASH_DISTANCE).clamp(arena.position, arena.end)
	$Ship.modulate = Color(0.5, 0.9, 1.0, 0.6)

	await get_tree().create_timer(DASH_IFRAMES).timeout
	dashing = false
	if not dead:
		$Ship.modulate = Color(1, 1, 1, 0.4) if invincible else Color.WHITE

func spawn_ghost():
	var ghost = Sprite2D.new()
	ghost.texture = $Ship.texture
	ghost.global_position = global_position
	ghost.global_rotation = $Ship.global_rotation
	ghost.scale = $Ship.global_scale
	ghost.modulate = Color(0.5, 0.9, 1.0, 0.7)
	get_parent().add_child(ghost)
	var t = ghost.create_tween()
	t.tween_property(ghost, "modulate:a", 0.0, 0.3)
	t.tween_callback(ghost.queue_free)

# ---------- Death ----------

func die():
	if dead:
		return
	dead = true
	hp = 0
	update_hearts()
	velocity = Vector2.ZERO
	$Ship.hide()
	$CollisionShape2D.set_deferred("disabled", true)

	var tween = create_tween()
	tween.tween_property(self, "boom", 1.0, 0.8)
	tween.tween_interval(0.6)
	tween.tween_callback(get_tree().reload_current_scene)

func _process(_delta):
	$Explosion.queue_redraw()

func _draw_explosion():
	if boom <= 0.0:
		return
	var fade = 1.0 - boom

	# Fireball
	var size = 15.0 + boom * 70.0
	$Explosion.draw_circle(Vector2.ZERO, size, Color(1, 0.5, 0.1, fade * 0.8))
	$Explosion.draw_circle(Vector2.ZERO, size * 0.55, Color(1, 0.95, 0.6, fade))

	# Shockwave ring
	$Explosion.draw_arc(Vector2.ZERO, 20.0 + boom * 140.0, 0, TAU, 48, Color(1, 0.8, 0.4, fade), 1.0 + fade * 6.0)

	# Debris
	for i in range(12):
		var dir = Vector2.RIGHT.rotated(i * TAU / 12.0 + 0.2)
		var reach = 40.0 + (i % 3) * 30.0 + boom * 110.0
		$Explosion.draw_line(dir * reach * 0.6, dir * reach, Color(1, 0.7, 0.3, fade), 4.0)
