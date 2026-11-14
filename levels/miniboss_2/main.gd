extends Node2D

# Arena backdrop. Powerups were removed for this mini-boss fight, so all that
# is left here is the faint border that marks the edge of the arena.

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var cam: Camera2D = get_viewport().get_camera_2d()
	var zoom: float = cam.zoom.x if cam else 1.0
	draw_rect(player.arena_rect(), Color(0.4, 0.8, 1.0, 0.35), false, 3.0 / zoom)
