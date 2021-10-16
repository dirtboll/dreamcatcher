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
onready var npc_clara				= $NPCClara

onready var dia_clara = Global.dialogue_json[name]["NPCClara"]

func _ready():
	if dialogue_box != null:
		start_act(ACT1)
	npc_clara.interactable = false
	level_trigger.interactable = false

	npc_clara.connect("interacted", self, "clara_interact")


func _process(_delta):
	if state == ACT1:
		if status == STARTED:
			player.set_physics_process(false)
			player.velocity = Vector2.ZERO
			
			dia_processor.connect("dialogue_finished", self, "finish_act")
			dia_processor.dia_start(Global.dialogue_json[name][name])
			status = GOING
		elif status == FINISHED:
			player.set_physics_process(true)
			start_act(IDLE)
			
			npc_clara.interactable = true
			level_trigger.interactable = true
			level_trigger.connect("interacted", game, "trans_scene_level")
	

func start_act(act: int):
	state = act
	status = STARTED


func finish_act():
	status = FINISHED
	dia_processor.disconnect("dialogue_finished", self, "finish_act")

#############################################################################


func clara_interact():
	var di_i = brain.get("scene_clara_dia_i", 0)
	if di_i < len(dia_clara) and not dia_processor.is_processing():
		dia_processor.dia_start([dia_clara[di_i]], true)
		di_i += 1
		brain["scene_clara_dia_i"] = di_i

		flip_on_interact(npc_clara)

		if di_i == 19:
			npc_clara.set_target(Vector2(-135,0))
			npc_clara.start_walk()
			npc_clara.connect("target_reached", self, "clara_reached")

	
func clara_reached():
	npc_clara.visible = false
	npc_clara.interactable = false


#############################################################################

func flip_on_interact(npc: Node2D):
	if player.global_position.x < npc.global_position.x:
		npc.anim_sprite.flip_h = true
	elif player.global_position.x > npc.global_position.x:
		npc.anim_sprite.flip_h = false
