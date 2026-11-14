extends Area2D

const WARN_TIME = 1.0
const FIRE_TIME = 0.4

var spark = 0.0

func _ready():
	$Sparks.z_index = 2
	body_entered.connect(_on_body_entered)
	$Sparks.draw.connect(_draw_sparks)
	$Visual.hide()
	$CollisionShape2D.disabled = true

	await get_tree().create_timer(WARN_TIME).timeout
	$Visual.show()
	$CollisionShape2D.disabled = false
	var tween = create_tween()
	tween.tween_property(self, "spark", 1.0, 0.35)

	await get_tree().create_timer(FIRE_TIME).timeout
	queue_free()

func _process(_delta):
	$Sparks.queue_redraw()

func _draw_sparks():
	if spark <= 0.0 or spark >= 1.0:
		return
	for i in range(8):
		var dir = Vector2.RIGHT.rotated(i * TAU / 8.0)
		var from = dir * (8.0 + spark * 45.0)
		var to = dir * (18.0 + spark * 65.0)
		$Sparks.draw_line(from, to, Color(1, 1, 0.7, 1.0 - spark), 3.0)

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(1)
