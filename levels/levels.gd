extends Node
# Autoloaded as "Levels". Runs the bosses in order: each boss calls
# Levels.boss_defeated() when it dies, which loads the next level.

const LEVELS = [
	"res://levels/miniboss_1/main.tscn",
	"res://levels/miniboss_2/main.tscn",
	"res://levels/final_boss/main.tscn",
]
const VICTORY = "res://levels/victory.tscn"
const NEXT_LEVEL_DELAY = 2.0

var advancing = false

func boss_defeated():
	if advancing:
		return
	advancing = true
	var current = get_tree().current_scene.scene_file_path
	var i = LEVELS.find(current)
	var next = VICTORY
	if i != -1 and i + 1 < LEVELS.size():
		next = LEVELS[i + 1]
	await get_tree().create_timer(NEXT_LEVEL_DELAY).timeout
	get_tree().change_scene_to_file(next)
	advancing = false

func restart():
	get_tree().change_scene_to_file(LEVELS[0])
