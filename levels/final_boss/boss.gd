extends Area2D

@export var max_hp = 200

const BEAM = preload("res://levels/final_boss/beam.tscn")
const BALL = preload("res://levels/final_boss/energy_ball.tscn")
const SHOCKWAVE = preload("res://levels/final_boss/shockwave.tscn")
const ORB = preload("res://levels/final_boss/spiral_orb.tscn")
const DEBRIS = preload("res://levels/final_boss/debris.tscn")
const RING = preload("res://levels/final_boss/ring_wave.tscn")
const SWEEP = preload("res://levels/final_boss/sweep_arms.tscn")
const BOSS_SCALE = 2.5
const STAR_RADIUS = 300.0
const SUN_TEXTURE = preload("res://assets/sun/sun.png")
const SUN_ART_RADIUS = 172.0   # radius of the sun disc in sun.png
const HOLE_RADIUS = 375.0 * BOSS_SCALE
const SPRITE_SCALE = 0.75 * BOSS_SCALE
# Black hole hitbox (in sprite pixels; scaled by SPRITE_SCALE)
const HOLE_BODY_RADIUS = 270.0
const HOLE_BODY_OFFSET = Vector2(0, 8)
const HOLE_DISK_SIZE = Vector2(920, 130)
const HOLE_DISK_OFFSET = Vector2(0, 48)
const BH_MAX_HP = 250
const CAM_ZOOM = 0.45
const CAM_ZOOM_NOVA = 0.3      # the wider shot for the supernova
const ARENA_P2 = Rect2(-2375, -1375, 5900, 3400)   # the play area in the black hole phase
const BAR_SPEED = 120.0       # how fast the HP bar fills or drains (HP per second)
const HOLE_SPEED_BOOST = 1.5
const DRIFT_AREA = Rect2(-600, -300, 2350, 1250)
const DRIFT_SPEED = 250.0
const DRIFT_STEER = 300.0
const MINION = preload("res://levels/final_boss/minion.tscn")
const MAX_MINIONS = 2
const SUMMON_WARN = 1.0
const PULL_MIN = 50.0
const PULL_MAX = 200.0
const PULL_RANGE = 2500.0

# Gravity surge
const SURGE_WARN = 1.0
const SURGE_HOLD = 2.5
const SURGE_FADE = 0.5
const SURGE_MULT = 2.0

# Spiral barrage
const SPIRAL_WARN = 0.8
const SPIRAL_TIME = 5.0
const SPIRAL_RATE = 0.14
const SPIRAL_ARMS = 3
const SPIRAL_TURN = 0.22
const SPIRAL_SPEED = 300.0

# Slingshot debris
const DEBRIS_TIME = 5.0
const DEBRIS_RATE = 0.5

# Accretion rings
const RING_COUNT = 3
const RING_SPACING = 1.5
const RING_WARN = 1.0
const RING_SPEED = 700.0
const RING_GAP = 1.4

# Absorb and return (buffed)
const ABSORB_WARN = 0.8
const ABSORB_TIME = 3.5
const ABSORB_MIN = 12
const ABSORB_MAX = 40
const ABSORB_HEAL = 0.5          # HP recovered per swallowed bullet (0 = off)
const RETURN_SPEED = 420.0
const RETURN_WAVES = 3
const RETURN_WAVE_GAP = 0.45
const RETURN_AIMED = 5           # orbs in the aimed fan on the first wave
const RETURN_AIMED_SPEED = 560.0

# Ultimate: Event Horizon Collapse (buffed)
const ULT_TRIGGER_HP = 30        # starts when the black hole drops to this
const ULT_HEAL_HP = 200          # and it recovers to this much
const ULT_CHARGE = 3.0
const ULT_SWEEP = 6.8            # matches sweep_arms.gd (0.8 warning + 6.0 active)
const ULT_PULSE_WARN = 2.0       # first pulse telegraph (as long as the dash cooldown)
const ULT_PULSE_GAP = 2.6        # second pulse launches this long after the first
const ULT_PULSE2_WARN = 1.2
const ULT_STUN_DELAY = 1.5
const ULT_STUN = 3.0
const ULT_PULL = 4.0
const ULT_ORB_RATE = 0.4         # orbs spiralling out during the sweep

var hp = 0
var phase = 1                 # 1 = star, 2 = black hole
var transitioning = false

# Animation values (tweened)
var star_visible = true
var star_scale = 1.0
var charge = 0.0
var flash = 0.0
var hole = 0.0
var shake = 0.0
var spin = 0.0

var drift_target = Vector2.ZERO
var drift_vel = Vector2.ZERO

# Black hole attack state
var attack = ""
var attack_time = 0.0
var next_attack_in = 2.0
var last_attack = ""
var surge = 1.0               # multiplies the gravity pull
var surge_fx = 0.0
var spiral_fx = 0.0
var spiral_cd = 0.0
var spiral_angle = 0.0
var spiral_dir = 1.0
var debris_cd = 0.0
var ring_spawned = 0
var ring_gap_center = 0.0
var absorbing = false
var summon_points = []
var absorbed = 0
var absorb_fx = 0.0
var return_waves = 0
var return_count = 0
var return_offset = 0.0
var ultimate_started = false
var ult_stage = 0
var ult_fx = 0.0
var inhale = 0.0
var stunned = false
var enraged = false

# Sprite effects (sheets from FX, see assets/fx/sun_blackhole_fx/README.md)
var sun_sprite = null        # the sun itself (Alan's art)
var sun_glow = null          # white-hot overlay as it collapses
var aura_fx = null           # sun_ring around the star
var swirl_fx = []            # ambient particles behind the black hole
var pull_fx = null           # gravity surge rings
var shield_fx = null         # absorb shield
var shield_hit_fx = null
var ult_ring_fx = null       # ultimate charging ring

func _ready():
	z_index = 1
	add_to_group("boss")
	# Give this boss its own copy of the shape, so resizing it later
	# doesn't carry over when the scene restarts
	$CollisionShape2D.shape = $CollisionShape2D.shape.duplicate()
	$CollisionShape2D.shape.radius = STAR_RADIUS

	make_fx()

	hp = max_hp
	$CanvasLayer/HPBar.max_value = max_hp
	$CanvasLayer/HPBar.value = hp
	$Timer.timeout.connect(fire_beams)
	body_entered.connect(_on_body_entered)
	$ShockTimer.timeout.connect(fire_shockwave)
	$ShockTimer.start(7.0)
	$BallTimer.timeout.connect(fire_balls)
	await get_tree().create_timer(2.0).timeout
	$BallTimer.start()

# ---------- Phase 1 attacks ----------

func fire_beams():
	var base_angle = PI
	var player = get_tree().get_first_node_in_group("player")
	if player:
		base_angle = (player.global_position - global_position).angle()

	for i in range(5):
		var angle = base_angle + deg_to_rad((i - 2) * 25)
		var beam = BEAM.instantiate()
		beam.global_position = global_position + Vector2.RIGHT.rotated(angle) * 300.0
		beam.rotation = angle
		get_parent().add_child(beam)

func fire_balls():
	for i in range(2):
		var ball = BALL.instantiate()
		var view = view_rect()
		var band = Vector2(100 + i * 250, 300 + i * 250) / 648.0   # top / bottom bands of the screen
		ball.global_position = Vector2(view.position.x + 60, view.position.y + view.size.y * randf_range(band.x, band.y))
		ball.target = self
		ball.velocity = Vector2(randf_range(50, 150), randf_range(-150, 150))
		get_parent().add_child(ball)

func fire_shockwave():
	var wave = SHOCKWAVE.instantiate()
	wave.global_position = global_position
	get_parent().add_child(wave)

# ---------- Damage ----------

func take_damage(amount):
	if transitioning:
		return
	if absorbing:
		# Absorb and return: swallow the bullet, count it, heal a little
		absorbed += 1
		shield_hit_fx.show()
		shield_hit_fx.play(&"v0")
		hp = min(hp + ABSORB_HEAL, BH_MAX_HP)
		return
	if stunned:
		amount *= 2   # free damage after surviving the ultimate

	hp -= amount

	if phase == 1 and hp <= 1:
		hp = 1
		start_transition()
	elif phase == 2:
		if hp <= 0:
			clear_attacks()
			queue_free()   # placeholder: black hole death goes here later
			Levels.boss_defeated()
		elif not ultimate_started and hp <= ULT_TRIGGER_HP:
			start_ultimate()

func _on_body_entered(body):
	if transitioning:
		return
	if body.has_method("die"):
		body.die()

# ---------- Star -> black hole ----------

func clear_attacks():
	var attack_scenes = [
		"res://levels/final_boss/beam.tscn",
		"res://levels/final_boss/energy_ball.tscn",
		"res://levels/final_boss/shockwave.tscn",
		"res://levels/final_boss/spiral_orb.tscn",
		"res://levels/final_boss/debris.tscn",
		"res://levels/final_boss/ring_wave.tscn",
		"res://levels/final_boss/minion.tscn",
	]
	for n in get_parent().get_children():
		if n.scene_file_path in attack_scenes:
			n.queue_free()

func start_transition():
	transitioning = true
	$Timer.stop()
	$BallTimer.stop()
	$ShockTimer.stop()
	clear_attacks()

	# 1. Collapse: the star shudders and whitens
	var collapse = create_tween().set_parallel(true)
	collapse.tween_property(self, "charge", 1.0, 1.4)
	collapse.tween_property(self, "star_scale", 0.8, 1.4)
	collapse.tween_property(self, "shake", 10.0, 1.4)
	await collapse.finished

	# 2. Supernova, with the camera zooming out. The sheet's first frame is
	# the sun itself, so it takes over from the star seamlessly.
	star_visible = false
	FX.spawn("sun_supernova", self, Vector2.ZERO, 0, FX.scale_for("sun_supernova", STAR_RADIUS * star_scale))
	flash = 1.0
	shake = 30.0
	var boom = create_tween().set_parallel(true)
	boom.tween_property(self, "flash", 0.0, 1.0)
	boom.tween_property(self, "shake", 0.0, 2.0)

	var cam = get_viewport().get_camera_2d()
	if cam:
		var zoom_out = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		zoom_out.tween_property(cam, "zoom", Vector2(CAM_ZOOM_NOVA, CAM_ZOOM_NOVA), 2.5)

	await get_tree().create_timer(1.4).timeout

	# 3. The black hole forms where the star was
	z_index = -1   # sits behind the ship now
	set_hole_hitbox()
	var form = create_tween()
	form.tween_property(self, "hole", 1.0, 1.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.stage_speed = HOLE_SPEED_BOOST
		player.fixed_arena = ARENA_P2
		player.use_fixed_arena = true
	if cam and "follow" in cam:
		cam.arena = ARENA_P2
		cam.follow = true

	hp = BH_MAX_HP
	$CanvasLayer/HPBar.max_value = BH_MAX_HP
	await form.finished

	phase = 2
	pick_drift_target()
	transitioning = false

# ---------- Phase 2 behaviour ----------

func _physics_process(delta):
	if phase != 2 or transitioning:
		return
	drift(delta)
	pull_player()
	run_attacks(delta)

func pick_drift_target():
	drift_target = Vector2(
		randf_range(DRIFT_AREA.position.x, DRIFT_AREA.end.x),
		randf_range(DRIFT_AREA.position.y, DRIFT_AREA.end.y))

func drift(delta):
	if global_position.distance_to(drift_target) < 150.0:
		pick_drift_target()
	var desired = (drift_target - global_position).normalized() * DRIFT_SPEED
	if stunned:
		desired = Vector2.ZERO
	drift_vel = drift_vel.move_toward(desired, DRIFT_STEER * delta)
	global_position += drift_vel * delta

func pull_player():
	if stunned:
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player or player.dead:
		return
	var to_hole = global_position - player.global_position
	var closeness = clamp(1.0 - to_hole.length() / PULL_RANGE, 0.0, 1.0)
	player.pull = to_hole.normalized() * lerp(PULL_MIN, PULL_MAX, closeness) * surge

func view_rect():
	var size = get_viewport_rect().size
	var cam = get_viewport().get_camera_2d()
	if cam:
		size = size / cam.zoom
		return Rect2(cam.get_screen_center_position() - size / 2.0, size)
	return Rect2(Vector2.ZERO, size)

# ---------- Attack scheduler ----------

func run_attacks(delta):
	if attack == "":
		next_attack_in -= delta
		if next_attack_in <= 0.0:
			start_attack()
		return

	attack_time += delta
	match attack:
		"surge":
			update_surge()
		"spiral":
			update_spiral(delta)
		"debris":
			update_debris(delta)
		"rings":
			update_rings()
		"absorb":
			update_absorb(delta)
		"summon":
			update_summon()
		"ultimate":
			update_ultimate(delta)

	attack_time += delta
	match attack:
		"surge":
			update_surge()
		"spiral":
			update_spiral(delta)
		"debris":
			update_debris(delta)
		"rings":
			update_rings()
		"absorb":
			update_absorb(delta)
		"ultimate":
			update_ultimate(delta)

func start_attack():
	var pool = ["spiral", "surge", "debris", "rings", "absorb"]
	if get_tree().get_nodes_in_group("minion").size() < MAX_MINIONS:
		pool.append("summon")        # only summons when there's room for more
	pool.erase(last_attack)          # never the same attack twice in a row
	attack = pool.pick_random()
	last_attack = attack
	attack_time = 0.0
	spiral_cd = 0.0
	spiral_dir = [-1.0, 1.0].pick_random()
	debris_cd = 0.0
	ring_spawned = 0
	absorbed = 0
	return_waves = 0
	if attack == "summon":
		plan_summon()

func end_attack():
	attack = ""
	surge = 1.0
	surge_fx = 0.0
	spiral_fx = 0.0
	absorbing = false
	absorb_fx = 0.0
	stunned = false
	ult_fx = 0.0
	inhale = 0.0
	ult_stage = 0
	# Once enraged (after the ultimate) it rests for a much shorter time
	next_attack_in = randf_range(1.0, 1.8) if enraged else randf_range(2.0, 3.0)

# ---------- Gravity surge ----------

func update_surge():
	var t = attack_time
	if t < SURGE_WARN:
		surge_fx = t / SURGE_WARN
		surge = 1.0
	elif t < SURGE_WARN + SURGE_HOLD:
		surge_fx = 1.0
		surge = lerp(1.0, SURGE_MULT, clamp((t - SURGE_WARN) / 0.3, 0.0, 1.0))
	elif t < SURGE_WARN + SURGE_HOLD + SURGE_FADE:
		var k = 1.0 - (t - SURGE_WARN - SURGE_HOLD) / SURGE_FADE
		surge_fx = k
		surge = lerp(1.0, SURGE_MULT, k)
	else:
		end_attack()

# ---------- Spiral barrage ----------

func update_spiral(delta):
	if attack_time < SPIRAL_WARN:
		spiral_fx = attack_time / SPIRAL_WARN
		return
	spiral_fx = 1.0
	if attack_time > SPIRAL_WARN + SPIRAL_TIME:
		end_attack()
		return

	spiral_cd -= delta
	if spiral_cd <= 0.0:
		spiral_cd = SPIRAL_RATE
		spiral_angle += SPIRAL_TURN * spiral_dir
		for i in range(SPIRAL_ARMS):
			spawn_orb(spiral_angle + i * TAU / SPIRAL_ARMS, SPIRAL_SPEED, "bh_matter_dots")

# sheet: "bh_matter_dots" or "bh_void_orbs". variant: 0/1/2 = small/medium/large
func spawn_orb(angle, orb_speed, sheet, variant = 1):
	var orb = ORB.instantiate()
	orb.global_position = global_position
	orb.velocity = Vector2.RIGHT.rotated(angle) * orb_speed
	orb.sheet = sheet
	orb.variant = variant
	get_parent().add_child(orb)

# ---------- Slingshot debris ----------

func update_debris(delta):
	if attack_time > DEBRIS_TIME:
		end_attack()
		return
	debris_cd -= delta
	if debris_cd <= 0.0:
		debris_cd = DEBRIS_RATE
		for i in range(2):
			spawn_debris()

func spawn_debris():
	var view = view_rect()
	var pos = Vector2.ZERO
	match randi() % 4:
		0:
			pos = Vector2(view.position.x - 40.0, randf_range(view.position.y, view.end.y))
		1:
			pos = Vector2(view.end.x + 40.0, randf_range(view.position.y, view.end.y))
		2:
			pos = Vector2(randf_range(view.position.x, view.end.x), view.position.y - 40.0)
		_:
			pos = Vector2(randf_range(view.position.x, view.end.x), view.end.y + 40.0)

	var rock = DEBRIS.instantiate()
	rock.global_position = pos
	rock.target = self
	var to_hole = (global_position - pos).normalized()
	rock.velocity = to_hole.rotated(randf_range(0.5, 1.0) * [-1.0, 1.0].pick_random()) * randf_range(250.0, 350.0)
	get_parent().add_child(rock)

# ---------- Accretion rings ----------

func update_rings():
	if ring_spawned < RING_COUNT and attack_time >= ring_spawned * RING_SPACING:
		if ring_spawned == 0:
			ring_gap_center = randf() * TAU
			var player = get_tree().get_first_node_in_group("player")
			if player:
				ring_gap_center = (player.global_position - global_position).angle() + randf_range(-0.5, 0.5)
		else:
			ring_gap_center += randf_range(0.2, 0.45) * [-1.0, 1.0].pick_random()
		spawn_ring(ring_gap_center, RING_GAP, RING_SPEED, RING_WARN, 40.0 * BOSS_SCALE, HOLE_RADIUS * 0.9, Color(1.0, 0.6, 0.25))
		ring_spawned += 1

	if attack_time > (RING_COUNT - 1) * RING_SPACING + RING_WARN + 2.5:
		end_attack()

func spawn_ring(gap_center, gap_width, ring_speed, warn, thickness, start_radius, col):
	var ring = RING.instantiate()
	ring.global_position = global_position
	ring.gap_center = gap_center
	ring.gap_width = gap_width
	ring.speed = ring_speed
	ring.warn_time = warn
	ring.thickness = thickness
	ring.start_radius = start_radius
	ring.color = col
	get_parent().add_child(ring)

# ---------- Absorb and return ----------

func update_absorb(delta):
	var t = attack_time
	var t_end = ABSORB_WARN + ABSORB_TIME

	if t < ABSORB_WARN:
		absorb_fx = t / ABSORB_WARN    # the shield fades in
		return
	if t < t_end:
		absorbing = true
		absorb_fx = 1.0
		return

	# The shield drops: lock in how many bullets it swallowed
	if absorbing:
		absorbing = false
		return_count = clampi(absorbed, ABSORB_MIN, ABSORB_MAX)
		return_offset = randf() * TAU
		absorb_fx = 0.0
		FX.spawn("bh_force_field_break", self, Vector2.ZERO, 0, shield_fx.scale.x)

	# Return fire in several waves
	if return_waves < RETURN_WAVES and t >= t_end + return_waves * RETURN_WAVE_GAP:
		fire_return_wave(return_waves)
		return_waves += 1
	elif return_waves >= RETURN_WAVES and t > t_end + RETURN_WAVES * RETURN_WAVE_GAP + 0.5:
		end_attack()

func fire_return_wave(k):
	var step = TAU / return_count
	for i in range(return_count):
		# every other wave is shifted half a step, so the gaps swap sides
		var a = return_offset + i * step + (k % 2) * step / 2.0
		spawn_orb(a, RETURN_SPEED, "bh_void_orbs")

	if k == 0:
		# a fast fan aimed straight at the ship
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var aim = (player.global_position - global_position).angle()
			for j in range(RETURN_AIMED):
				spawn_orb(aim + (j - (RETURN_AIMED - 1) / 2.0) * 0.12, RETURN_AIMED_SPEED, "bh_void_orbs", 2)

	shake = 12.0
	create_tween().tween_property(self, "shake", 0.0, 0.4)

# ---------- Ultimate: Event Horizon Collapse ----------

func start_ultimate():
	ultimate_started = true
	end_attack()          # cancel whatever it was doing
	clear_attacks()
	hp = ULT_HEAL_HP      # it recovers while it charges, and the bar refills smoothly
	attack = "ultimate"
	attack_time = 0.0

func update_ultimate(delta):
	var t = attack_time
	var t_sweep = ULT_CHARGE
	var t_pulse = t_sweep + ULT_SWEEP
	var t_launch = t_pulse + ULT_PULSE_WARN
	var t_launch2 = t_launch + ULT_PULSE_GAP
	var t_warn2 = t_launch2 - ULT_PULSE2_WARN
	var t_stun = t_launch2 + ULT_STUN_DELAY
	var t_end = t_stun + ULT_STUN

	if t < t_sweep:
		# 1. Charge: the screen darkens, the camera pushes in, gravity ramps up
		var k = t / ULT_CHARGE
		ult_fx = k
		surge = lerp(1.0, ULT_PULL, k)
	elif t < t_pulse:
		# 2. Sweep: five beam arms that reverse halfway, plus a sparse orb spiral
		if ult_stage < 1:
			ult_stage = 1
			add_child(SWEEP.instantiate())
		ult_fx = 1.0
		surge = 1.8
		spiral_cd -= delta
		if spiral_cd <= 0.0:
			spiral_cd = ULT_ORB_RATE
			spiral_angle += 0.5
			for i in range(2):
				spawn_orb(spiral_angle + i * PI, 260.0, "bh_matter_dots")
	elif t < t_launch:
		# 3. Inhale: gravity lets go, the first pulse is telegraphed
		if ult_stage < 2:
			ult_stage = 2
			spawn_pulse(ULT_PULSE_WARN, 700.0 * BOSS_SCALE, Color(0.85, 0.7, 1.0))
		surge = 1.0
		inhale = (t - t_pulse) / ULT_PULSE_WARN
	elif t < t_launch2:
		# 4. First pulse released, second one winding up
		if ult_stage < 3:
			ult_stage = 3
			inhale = 0.0
			ult_burst()
		if t >= t_warn2:
			if ult_stage < 4:
				ult_stage = 4
				spawn_pulse(ULT_PULSE2_WARN, 800.0 * BOSS_SCALE, Color(1.0, 0.6, 0.9))
			inhale = (t - t_warn2) / ULT_PULSE2_WARN
	elif t < t_stun:
		# 5. Second pulse released
		if ult_stage < 5:
			ult_stage = 5
			inhale = 0.0
			ult_burst()
		ult_fx = move_toward(ult_fx, 0.0, delta)
	elif t < t_end:
		# 6. Stunned: no drift, no pull, double damage
		if ult_stage < 6:
			ult_stage = 6
			stunned = true
		ult_fx = move_toward(ult_fx, 0.0, delta)
	else:
		enraged = true
		end_attack()

func spawn_pulse(warn, pulse_speed, col):
	spawn_ring(0.0, 0.0, pulse_speed, warn, 90.0 * BOSS_SCALE, HOLE_RADIUS * 0.9, col)

func ult_burst():
	FX.spawn("bh_ult_ring", self, Vector2.ZERO, 0, FX.scale_for("bh_ult_ring", HOLE_RADIUS * 1.2))
	shake = 25.0
	flash = 0.6
	var burst = create_tween().set_parallel(true)
	burst.tween_property(self, "shake", 0.0, 0.8)
	burst.tween_property(self, "flash", 0.0, 0.5)

# ---------- Drawing ----------

func _process(delta):
	spin += delta * 1.5
	$CanvasLayer/HPBar.value = move_toward($CanvasLayer/HPBar.value, hp, BAR_SPEED * delta)
	queue_redraw()
	update_fx()

	var cam = get_viewport().get_camera_2d()
	if cam:
		cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake
		if phase == 2 and not transitioning:
			var z = CAM_ZOOM * (1.0 + 0.12 * ult_fx)   # pushes in during the ultimate
			cam.zoom = cam.zoom.lerp(Vector2(z, z), 1.0 - exp(-3.0 * delta))

	var stun_fx = 1.0 if stunned else 0.0
	var squeeze = 1.0 - 0.15 * surge_fx + 0.08 * spiral_fx - 0.25 * inhale
	var tint = Color.WHITE.lerp(Color(1, 0.55, 0.55), surge_fx).lerp(Color(1, 0.8, 0.5), spiral_fx)
	tint = tint.lerp(Color(0.55, 0.6, 1.0), stun_fx)
	if enraged:
		tint = tint.lerp(Color(1.0, 0.75, 0.75), 0.3)
	tint.a = clamp(hole, 0.0, 1.0)
	$HoleSprite.visible = hole > 0.0
	$HoleSprite.scale = Vector2.ONE * SPRITE_SCALE * hole * squeeze
	$HoleSprite.modulate = tint
	$HoleSprite.position.y = sin(spin * 1.2) * 8.0
	$HoleSprite.position.x = randf_range(-1.0, 1.0) * 5.0 * surge_fx

func _draw():
	if ult_fx > 0.0:
		draw_rect(Rect2(-8000, -8000, 16000, 16000), Color(0.0, 0.0, 0.05, ult_fx * 0.55))
	if attack == "summon" and not summon_points.is_empty():
		draw_summon()
	if stunned:
		draw_stun()
	if flash > 0.0:
		draw_rect(Rect2(-8000, -8000, 16000, 16000), Color(1, 1, 1, flash))

func draw_stun():
	var s = BOSS_SCALE
	for i in range(6):
		var a = spin * 2.5 + i * TAU / 6.0
		var p = Vector2(cos(a) * 260.0 * s, -330.0 * s + sin(a) * 40.0 * s)
		draw_circle(p, 12.0 * s, Color(1.0, 0.9, 0.3))

func set_hole_hitbox():
	# Body: a circle on the round part of the black hole
	$CollisionShape2D.shape.radius = HOLE_BODY_RADIUS * SPRITE_SCALE
	$CollisionShape2D.position = HOLE_BODY_OFFSET * SPRITE_SCALE
	$CollisionShape2D.scale = Vector2.ONE

	# Disk: a wide, thin rectangle across the middle
	var disk = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = HOLE_DISK_SIZE * SPRITE_SCALE
	disk.shape = rect
	disk.position = HOLE_DISK_OFFSET * SPRITE_SCALE
	add_child(disk)
# ---------- Summon minions ----------

func plan_summon():
	summon_points.clear()
	var count = 2
	var base = randf() * TAU
	for i in range(count):
		var a = base + i * TAU / count
		summon_points.append(global_position + Vector2.RIGHT.rotated(a) * HOLE_RADIUS * 1.15)

func update_summon():
	if attack_time < SUMMON_WARN:
		spiral_fx = attack_time / SUMMON_WARN    # the black hole swells and glows
		return
	for p in summon_points:
		var m = MINION.instantiate()
		m.global_position = p
		get_parent().add_child(m)
	summon_points.clear()
	end_attack()

func draw_summon():
	# Shrinking rings mark where the minions are about to appear
	var t = attack_time / SUMMON_WARN
	for p in summon_points:
		var lp = to_local(p)
		draw_arc(lp, 160.0 * BOSS_SCALE * (1.0 - t * 0.7), 0, TAU, 48, Color(1.0, 0.4, 0.6, 0.4 + 0.5 * t), 6.0 * BOSS_SCALE)
		draw_circle(lp, 40.0 * BOSS_SCALE * t, Color(1.0, 0.4, 0.6, 0.35))

# ---------- Sprite effects ----------

func make_fx():
	sun_sprite = Sprite2D.new()
	sun_sprite.texture = SUN_TEXTURE
	sun_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sun_sprite)
	sun_glow = Sprite2D.new()
	sun_glow.texture = SUN_TEXTURE
	var add = CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sun_glow.material = add
	sun_glow.modulate.a = 0.0
	sun_sprite.add_child(sun_glow)

	aura_fx = FX.spawn("sun_ring", self, Vector2.ZERO, 0, FX.scale_for("sun_ring", STAR_RADIUS))

	# Behind the black hole sprite
	for key in ["bh_random_particles", "bh_spiral_particles"]:
		var p = FX.spawn(key, self)
		p.hide()
		swirl_fx.append(p)
	pull_fx = FX.spawn("bh_gravity_pull", self, Vector2.ZERO, 0, FX.scale_for("bh_gravity_pull", HOLE_RADIUS * 2.0))
	pull_fx.hide()
	for n in swirl_fx + [pull_fx]:
		move_child(n, $HoleSprite.get_index())

	# In front of it
	var shield_scale = FX.scale_for("bh_force_field", HOLE_RADIUS + 25.0 * BOSS_SCALE)
	shield_fx = FX.spawn("bh_force_field", self, Vector2.ZERO, 0, shield_scale)
	shield_fx.hide()
	shield_hit_fx = FX.spawn("bh_force_field_hit", self, Vector2.ZERO, 0, shield_scale)
	shield_hit_fx.animation_finished.disconnect(shield_hit_fx.queue_free)   # reused for every hit
	shield_hit_fx.animation_finished.connect(shield_hit_fx.hide)
	shield_hit_fx.hide()
	ult_ring_fx = FX.spawn("bh_ult_ring_loop", self, Vector2.ZERO, 0, FX.scale_for("bh_ult_ring_loop", HOLE_RADIUS))
	ult_ring_fx.hide()

func update_fx():
	# the sun holds still; it only shudders while collapsing into the supernova
	var jitter = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * charge * 10.0
	sun_sprite.visible = star_visible
	sun_sprite.scale = Vector2.ONE * STAR_RADIUS * star_scale / SUN_ART_RADIUS
	sun_sprite.position = jitter
	sun_glow.modulate.a = charge
	aura_fx.visible = star_visible
	aura_fx.scale = Vector2.ONE * FX.scale_for("sun_ring", STAR_RADIUS * star_scale)
	aura_fx.position = jitter

	for p in swirl_fx:
		p.visible = hole > 0.0
		p.scale = Vector2.ONE * FX.scale_for("bh_spiral_particles", HOLE_RADIUS * 1.1) * hole
		p.modulate.a = clamp(hole, 0.0, 1.0)

	pull_fx.visible = surge_fx > 0.0
	pull_fx.modulate.a = surge_fx

	shield_fx.visible = absorb_fx > 0.0
	shield_fx.modulate.a = absorb_fx
	if not absorbing:
		shield_hit_fx.hide()

	# charging the ultimate, and while each pulse winds up
	var ult_charging = attack == "ultimate" and (ult_stage == 0 or inhale > 0.0)
	ult_ring_fx.visible = ult_charging
	if ult_charging:
		var k = attack_time / ULT_CHARGE if ult_stage == 0 else inhale
		ult_ring_fx.modulate.a = clamp(k, 0.0, 1.0)
