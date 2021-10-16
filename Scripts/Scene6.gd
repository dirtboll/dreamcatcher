extends Node2D

enum {
	IDLE,
	ACT1,
	ACT2,
}

enum {
	STARTED,
	GOING,
	FINISHED
}

var state = IDLE
var status = STARTED
var i = 0

var brain: Dictionary = {}

onready var game 				   := get_node_or_null("/root/Game")
onready var dialogue_box 		   := get_node_or_null("/root/Game/DialogueBox")
onready var dia_processor: Node2D 	= $DialogueProcessor
onready var level_trigger			= $Triggers/LevelTrigger
onready var player: KinematicBody2D = $Player2

func _ready():
	if dialogue_box != null:
		start_act(ACT1)


func _process(_delta):
	if state == ACT1:
		if status == STARTED:
			player.set_physics_process(false)
			player.velocity = Vector2.ZERO
			
			dia_processor.connect("dialogue_finished", self, "finish_act")
			dia_processor.dia_start(Global.dialogue_json[name][name])
			status = GOING
		elif status == FINISHED:
			Global.difficulty = 20
			game.trans_scene_level()
	

func start_act(act: int):
	state = act
	status = STARTED


func finish_act():
	status = FINISHED
	dia_processor.disconnect("dialogue_finished", self, "finish_act")

#############################################################################


#############################################################################

func flip_on_interact(npc: Node2D):
	if player.global_position.x < npc.global_position.x:
		npc.anim_sprite.flip_h = true
	elif player.global_position.x > npc.global_position.x:
		npc.anim_sprite.flip_h = false
