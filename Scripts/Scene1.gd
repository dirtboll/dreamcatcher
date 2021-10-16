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
onready var trigger1                = $Triggers/Trigger1
onready var scene_trigger			= $Triggers/SceneTrigger
onready var player: KinematicBody2D = $Player2
onready var npc_clara				= $NPCClara
onready var npc_chika				= $NPCChika
onready var npc_luna				= $NPCLuna

onready var dia_luna = Global.dialogue_json["Scene1"]["NPCLuna"]
onready var dia_clara = Global.dialogue_json["Scene1"]["NPCClara"]
onready var dia_chika = Global.dialogue_json["Scene1"]["NPCChika"]

func _ready():
	if dialogue_box != null:
		start_act(ACT1)
	npc_chika.connect("interacted", self, "chika_interact")
	npc_clara.connect("interacted", self, "clara_interact")
	npc_luna.connect("interacted", self, "luna_interact")


func _process(_delta):
	if state == ACT1:
		if status == STARTED:
			player.set_physics_process(false)
			player.velocity = Vector2.ZERO
			
			dia_processor.connect("dialogue_finished", self, "finish_act")
			dia_processor.dia_start(Global.dialogue_json["Scene1"]["Scene1"])
			status = GOING
		elif status == FINISHED:
			player.set_physics_process(true)
			start_act(IDLE)

	elif state == ACT2:
		if status == STARTED:
			player.set_physics_process(false)
			player.velocity = Vector2.ZERO
			trigger1.queue_free()
			
			dia_processor.connect("dialogue_finished", self, "finish_act")
			dia_processor.connect("dialogue_changed", self, "act2_luna_walk")
			dia_processor.dia_start(Global.dialogue_json["Scene1"]["Trigger1"])
			status = GOING
		elif status == FINISHED:
			npc_chika.interactable = true
			npc_luna.interactable = true
			npc_clara.interactable = true
			
			scene_trigger.interactable = true
			scene_trigger.visible = true
			scene_trigger.connect("interacted", game, "trans_scene_progress", [ "res://Scenes/Scene2.tscn" ])

			player.set_physics_process(true)
			start_act(IDLE)


func _on_Trigger1_body_entered(_body: Node2D):
	start_act(ACT2)
	

func start_act(act: int):
	state = act
	status = STARTED


func finish_act():
	status = FINISHED
	dia_processor.disconnect("dialogue_finished", self, "finish_act")

#############################################################################


func luna_interact():
	var di_i = brain.get("scene1_luna_dia_i", 0)
	if di_i < len(dia_luna) and not dia_processor.is_processing():
		dia_processor.dia_start([dia_luna[di_i]], true)
		di_i += 1
		brain["scene1_luna_dia_i"] = di_i
		npc_luna.stop_walk()
		dia_processor.connect("dialogue_finished", self, "luna_dia_finished")

		flip_on_interact(npc_luna)

func luna_dia_finished():
	dia_processor.disconnect("dialogue_finished", self, "luna_dia_finished")
	npc_luna.start_walk()

func clara_interact():
	var di_i = brain.get("scene1_clara_dia_i", 0)
	if di_i < len(dia_clara) and not dia_processor.is_processing():
		dia_processor.dia_start([dia_clara[di_i]], true)
		di_i += 1
		brain["scene1_clara_dia_i"] = di_i

		flip_on_interact(npc_clara)

func chika_interact():
	var di_i = brain.get("scene1_chika_dia_i", 0)
	if di_i < len(dia_chika) and not dia_processor.is_processing():
		dia_processor.dia_start([dia_chika[di_i]], true)
		di_i += 1
		brain["scene1_chika_dia_i"] = di_i

		flip_on_interact(npc_chika)

	
#############################################################################
func act2_luna_walk():
	if dia_processor.dia_i == 43:
		dia_processor.disconnect("dialogue_changed", self, "act2_luna_walk")
		npc_luna.set_target(Vector2(314,0))
		npc_luna.connect("target_reached", self, "act2_luna_reach")

func act2_luna_reach():
	npc_luna.disconnect("target_reached", self, "act2_luna_reach")
	npc_luna.visible = false
	npc_luna.interactable = false


func flip_on_interact(npc: Node2D):
	if player.global_position.x < npc.global_position.x:
		npc.anim_sprite.flip_h = true
	elif player.global_position.x > npc.global_position.x:
		npc.anim_sprite.flip_h = false
