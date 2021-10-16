tool
extends Node2D

var difficulty = Global.difficulty
var mob_spawn_cd = 1
var mob_cap_mult = 4
var mob_cap_max = 30
var mob_cap = clamp(mob_cap_mult * (difficulty * 2), 1, mob_cap_max)
var mob_num = 0
var mob_spawners := {}
var spawned_mobs := {}
var level_dia_key = Global.get_level_dialogue_key()
var dialogues = []

var coll_scn_dict = {
	10: preload("res://Scenes/CollectableDuck.tscn"),
	9: preload("res://Scenes/CollectableSign.tscn"),
	8: preload("res://Scenes/CollectableTorch.tscn")
}

onready var game 						= get_node_or_null("/root/Game")
onready var dia_processor				= $DialogueProcessor
onready var map: TileMap 				= $MapGen
onready var player_spawn_area: Area2D 	= $SpawnArea
onready var end_area: StaticBody2D 		= $EndArea
onready var player 						:= $Player
onready var spawn_trigger 				:= player.get_node("SpawnerTriggerArea")
onready var spawn_ignore 				:= player.get_node("SpawnerPreventArea")
onready var despawn_area: Area2D 		= player.get_node("DespawnArea")
onready var mob_spawner: PackedScene 	= preload("res://Scenes/MobSpawner.tscn")
onready var timer_spawn 				:= Timer.new()

onready var mobs := [
	preload("res://Scenes/EnemySlime.tscn"),
	preload("res://Scenes/EnemyBat.tscn")
]

func _process(_delta):
	#print(mob_num)
	pass

func _ready():
	randomize()
	timer_spawn.connect("timeout", self, "spawn_mobs")
	add_child(timer_spawn)
	timer_spawn.start(mob_spawn_cd)

	despawn_area.connect("body_exited", self, "despawn_mob")

	player_spawn_area.position = map.spawn_pos
	end_area.position = map.end_pos
	end_area.interactable = true

	for pos in map.mob_spawners.keys():
		var area = mob_spawner.instance()
		area.position = pos
		add_child(area)
		mob_spawners[area] = map.mob_spawners[pos]
	for collectables in map.generated_collectables:
		var pos = collectables[0]
		var coll = coll_scn_dict[collectables[2]].instance()
		coll.global_position = pos
		coll.tilemap = map
		coll.tile_pos = collectables[1]
		add_child(coll)

	player.position = player_spawn_area.position
	player.connect("died", self, "player_death")

	if game != null:
		end_area.connect("interacted", game, "level_finish")

	dialogues =	Global.dialogue_json.get(level_dia_key, {}).get(level_dia_key, [])
	dia_processor.dia_start(dialogues, true)
	

func spawn_mobs():
	if mob_num < mob_cap:
		var spawner_areas = spawn_trigger.get_overlapping_areas()
		spawner_areas.sort_custom(self, "spawn_sort")
		var spawner_filtered = []
		var i = 0
		while i < len(spawner_areas):
			var spawner_area = spawner_areas[i]
			i += 1
			if spawner_area.overlaps_area(spawn_ignore):
				continue
			spawner_filtered.append(spawner_area)
			
		
		var spawner_area = _rand_choose(spawner_filtered)
		if spawner_area != null:
			var spawner = mob_spawners[spawner_area]
			var mob = mobs[spawner.i].instance()
			mob.position = spawner_area.position
			add_child(mob)
			mob_num += 1
			spawned_mobs[mob] = "ehe"
		else:
			spawner_areas.remove(spawner_area)
	
func despawn_mob(node: Node2D):
	if spawned_mobs.erase(node):
		mob_num -= 1
		node.queue_free()

func player_death():
	Global.deaths += 1
	game.trans_scene_died()

func spawn_sort(a, b):
	return a.global_position.distance_squared_to(player.global_position) < b.global_position.distance_squared_to(player.global_position)

func _rand_choose(arr: Array):
	if len(arr) == 0: 
		return
	return arr[randi() % len(arr)]
