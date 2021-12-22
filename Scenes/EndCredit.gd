extends Node2D

onready var dialogue_box 		   := get_node_or_null("/root/Game/DialogueBox")
onready var dia_processor: Node2D 	= $DialogueProcessor
onready var text_rect 				= $Player2Rect
onready var end_text                = $the_end

var stage = 0
var doing = false

func _ready():
	dialogue_box.interactable = false

	text_rect.brighten()
	yield(text_rect, "done")
	dialogue_box.start_dialogue("Luna", "I know you haven't sleep yet. I'm sorry")
	yield(dialogue_box, "dialogue_finished")

	yield(get_tree().create_timer(1), "timeout")

	dialogue_box.start_dialogue("Luna", "It's ok, your journey has ended right now. For now...")
	yield(dialogue_box, "dialogue_finished")

	yield(get_tree().create_timer(2), "timeout")

	dialogue_box.start_dialogue("Luna", "It's just a nightmare...")
	yield(dialogue_box, "dialogue_finished")

	yield(get_tree().create_timer(2), "timeout")

	dialogue_box.start_dialogue("Luna", "And I'm always here for you...")
	yield(dialogue_box, "dialogue_finished")

	yield(get_tree().create_timer(2), "timeout")

	dialogue_box.start_dialogue("Luna", "As your Dreamcatcher.")
	yield(dialogue_box, "dialogue_finished")

	yield(get_tree().create_timer(2), "timeout")

	dialogue_box.start_dialogue("Luna", "Take care.")
	yield(dialogue_box, "dialogue_finished")

	yield(get_tree().create_timer(2), "timeout")
	dialogue_box.close_dialogue()
	end_text.brighten()
	yield(end_text, "done")

	yield(get_tree().create_timer(2), "timeout")
	end_text.dim()

	get_tree().quit()


func _process(_delta):
	pass

func done():
	doing = false
