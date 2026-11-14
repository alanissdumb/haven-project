extends Area2D

const SPEED = 800.0
const HOMING_RATE = 1.6        # radians per second it can curve (kept slight)
const HOMING_RANGE = 900.0     # only minions this close
const HOMING_CONE = 0.9        # only minions within about 50 degrees of where it's heading
const HIT_FX = preload("res://levels/final_boss/hit_fx.tscn")

var direction = Vector2.RIGHT
var damage = 1

func _ready():
	area_entered.connect(_on_area_entered)
	$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)

func _physics_process(delta):
	steer_to_minion(delta)
	position += direction * SPEED * delta

func steer_to_minion(delta):
	var best = null
	var best_dist = HOMING_RANGE
	for m in get_tree().get_nodes_in_group("minion"):
		var to_m = m.global_position - global_position
		var d = to_m.length()
		if d < best_dist and abs(direction.angle_to(to_m)) < HOMING_CONE:
			best = to_m
			best_dist = d
	if best == null:
		return
	var turn = clamp(direction.angle_to(best), -HOMING_RATE * delta, HOMING_RATE * delta)
	direction = direction.rotated(turn)
	rotation = direction.angle()

func _on_area_entered(area):
	if area.has_method("take_damage"):
		area.take_damage(damage)

		var fx = HIT_FX.instantiate()
		fx.global_position = global_position
		fx.big = false
		if area.get("absorbing") == true:
			fx.color = Color(0.4, 0.9, 1.0)
		get_parent().add_child(fx)
		queue_free()
