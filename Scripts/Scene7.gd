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
onready var npc_luna				= $NPCLuna
onready var text_rect 				= $Player2Rect

onready var dia_luna = Global.dialogue_json[name]["NPCLuna"]

func _ready():
	if dialogue_box != null:
		start_act(ACT1)
	npc_luna.interactable = true
	level_trigger.interactable = true

	npc_luna.connect("interacted", self, "luna_interact")
	level_trigger.connect("interacted", self, "finish")
	text_rect.color.a = 0


func _process(_delta):
	pass
	

func finish():
	level_trigger.interactable = false
	npc_luna.interactable = false
	text_rect.dim()
	text_rect.connect("done", self, "transition_finish")

func transition_finish():
	game.trans_scene_progress("EndCredit")

func start_act(act: int):
	state = act
	status = STARTED


func finish_act():
	status = FINISHED
	dia_processor.disconnect("dialogue_finished", self, "finish_act")

#############################################################################


func luna_interact():
	var di_i = brain.get("scene_luna_dia_i", 0)
	if di_i < len(dia_luna) and not dia_processor.is_processing():
		dia_processor.dia_start([dia_luna[di_i]])
		di_i += 1
		brain["scene_luna_dia_i"] = di_i


#############################################################################

func flip_on_interact(npc: Node2D):
	if player.global_position.x < npc.global_position.x:
		npc.anim_sprite.flip_h = true
	elif player.global_position.x > npc.global_position.x:
		npc.anim_sprite.flip_h = false
