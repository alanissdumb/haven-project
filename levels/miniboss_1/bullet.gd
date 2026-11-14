extends Area2D

const SPEED = 800.0
var direction = Vector2.RIGHT

func _ready():
	area_entered.connect(_on_area_entered)
	$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)

func _physics_process(delta):
	position += direction * SPEED * delta

func _on_area_entered(area):
	if area.has_method("take_damage"):
		area.take_damage(1)
		queue_free()
