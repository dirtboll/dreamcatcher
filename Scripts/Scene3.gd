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

onready var dia_luna = Global.dialogue_json[name]["NPCLuna"]

func _ready():
	if dialogue_box != null:
		start_act(ACT1)
	npc_luna.interactable = false
	level_trigger.interactable = false

	npc_luna.connect("interacted", self, "luna_interact")


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
			
			npc_luna.interactable = true
			level_trigger.interactable = true
			level_trigger.connect("interacted", game, "trans_scene_level")
	

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
		dia_processor.dia_start([dia_luna[di_i]], true)
		di_i += 1
		brain["scene_luna_dia_i"] = di_i

		flip_on_interact(npc_luna)

		if di_i == 19:
			npc_luna.set_target(Vector2(-135,0))
			npc_luna.start_walk()
			npc_luna.connect("target_reached", self, "luna_reached")

	
func luna_reached():
	npc_luna.visible = false
	npc_luna.interactable = false


#############################################################################

func flip_on_interact(npc: Node2D):
	if player.global_position.x < npc.global_position.x:
		npc.anim_sprite.flip_h = true
	elif player.global_position.x > npc.global_position.x:
		npc.anim_sprite.flip_h = false
