extends Control

onready var viewport = $ViewportContainer/Viewport
onready var dialogue_box = $DialogueBox

func _ready():
	trans_scene_progress(Global.get_the_scene())

func _trans_scene(path: String):
	for node in viewport.get_children():
		node.visible = false
		node.queue_free()
	dialogue_box.close_dialogue()
	viewport.add_child(load(path).instance())

func trans_scene_progress(path: String):
	_trans_scene(path)
	Global.current_scene = path

func trans_scene_level():
	_trans_scene("res://Scenes/Level.tscn")

func trans_scene_died():
	_trans_scene("res://Scenes/SceneDead.tscn")

func level_finish():
	Global.difficulty += 1
	_trans_scene(Global.get_diff_scene())
