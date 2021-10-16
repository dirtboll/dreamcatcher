extends Node

const DIFF_TO_SCENE = {
	2: "res://Scenes/Scene3.tscn",
	3: "res://Scenes/Scene4.tscn",
	4: "res://Scenes/Scene5.tscn",
	5: "res://Scenes/Scene6.tscn",
	21: "res://Scenes/Scene7.tscn"
}
var deaths = 0
var difficulty = 1
var current_scene = "Scene1"
var dia_auto_end_time = 3
onready var file = File.new()
onready var dialogue_json = {}

func _ready():
	file.open("res://Assets/dialogue.json", file.READ)
	dialogue_json = JSON.parse(file.get_as_text()).result


func get_the_scene():
	return "res://Scenes/" + current_scene + ".tscn"


func get_diff_scene():
	var scene = DIFF_TO_SCENE.get(difficulty, null)
	if scene == null:
		return "res://Scenes/Level.tscn"
	else:
		return scene


func get_tile_dist():
	var dict = {
		2: 0.5,
	
		18: 0.75,  #Grass
		23: 0.05,  #Mushroom right
		24: 0.05,  #Mushroom left
		25: 0.7,   #Hanging
	
		14: 1.0,   #Mob Spawn
	
		10: 0.03,   #Duck (Heal)
		9:  0.03,   #Sign (Path Helper)
		8:  0.03    #Torch (Lighting)
	}

	if difficulty < 2:
		dict[8] = 0.0
	if difficulty < 3:
		dict[9] = 0.0
	if difficulty < 4:
		dict[10] = 0.0

	return dict

func get_scene_died():
	var tscn = load("res://Scenes/" +  current_scene + "Dead.tscn")
	if tscn != null:
		return "res://Scenes/" +  current_scene + "Dead.tscn"
	else:
		return get_the_scene()

func get_level_dialogue_key():
	return "Level" + str(difficulty)

func get_tile_group():
	var dict = {
		2: [],
		14:  [14],
		18:  [11,12,13,15,16,17,18,21],
		23:  [23],
		24:  [24],
		25:  [25,26,27,28,29],
		22:  [22]
	}
	if difficulty > 3:
		dict[14].append(19)
	# if difficulty > 10:
	# 	dict[14].append(20)
	return dict
