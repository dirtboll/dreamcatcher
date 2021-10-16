extends Node2D

enum {
	IDLE,
	ACT1
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
	level_trigger.interactable = false


func _process(_delta):
	if state == ACT1:
		if status == STARTED:

			level_trigger.interactable = true
			level_trigger.connect("interacted", game, "trans_scene_level")
			
			dia_processor.connect("dialogue_finished", self, "finish_act")
			
			var dialogues = Global.dialogue_json.get(name, {}).get("Death"+str(Global.deaths),[])
			dia_processor.dia_start(dialogues, true)
			status = GOING
		elif status == FINISHED:
			player.set_physics_process(true)
			start_act(IDLE)
	

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
