extends Node2D

const POWERUP = preload("res://levels/final_boss/powerup.tscn")

const SPAWN_EVERY = Vector2(10.0, 16.0)   # random wait between mystery boxes (seconds)
const MAX_POWERUPS = 2
const SUPER_COOLDOWN = 25.0

var next_spawn = 8.0
var super_cd = 0.0

func _process(delta):
	queue_redraw()
	var player = get_tree().get_first_node_in_group("player")
	if player == null or player.dead:
		return

	next_spawn -= delta
	super_cd -= delta

	if next_spawn <= 0.0:
		next_spawn = randf_range(SPAWN_EVERY.x, SPAWN_EVERY.y)
		if get_tree().get_nodes_in_group("powerup").size() < MAX_POWERUPS:
			spawn_powerup("")

	# Guaranteed overcharge: black hole stage and down to 1 HP
	var boss = get_tree().get_first_node_in_group("boss")
	if boss and boss.phase == 2 and not boss.transitioning and player.hp == 1 and super_cd <= 0.0:
		if get_tree().get_nodes_in_group("super_powerup").is_empty() and not player.buffs.has("super"):
			super_cd = SUPER_COOLDOWN
			spawn_powerup("super")

func spawn_powerup(kind):
	var player = get_tree().get_first_node_in_group("player")
	var p = POWERUP.instantiate()
	p.kind = kind
	p.global_position = find_spawn_point(player)
	add_child(p)

func find_spawn_point(player):
	var cam = get_viewport().get_camera_2d()
	var zoom = cam.zoom.x if cam else 1.0
	var reach = get_viewport_rect().size.y / zoom * 0.35   # "not too far", scaled to the camera
	var arena = player.arena_rect()
	var boss = get_tree().get_first_node_in_group("boss")
	var pos = player.global_position
	for i in range(15):
		pos = player.global_position + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(reach * 0.4, reach)
		pos = pos.clamp(arena.position, arena.end)
		if boss == null:
			break
		var avoid = boss.STAR_RADIUS if boss.phase == 1 else boss.HOLE_RADIUS
		if pos.distance_to(boss.global_position) > avoid + 150.0:
			break   # not on top of the boss
	return pos

func _draw():
	# Faint border showing the edge of the arena
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var cam = get_viewport().get_camera_2d()
	var zoom = cam.zoom.x if cam else 1.0
	draw_rect(player.arena_rect(), Color(0.4, 0.8, 1.0, 0.35), false, 3.0 / zoom)
