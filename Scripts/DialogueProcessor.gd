extends Node2D

enum State {
	IDLE,
	PROCESSING
}

signal dialogue_started()
signal dialogue_changed()
signal dialogue_finished()

var dialogues = []
var dia_i = -1
var state = State.IDLE
var auto_end = false

onready var dialogue_box := get_node_or_null("/root/Game/DialogueBox")
onready var dia_timer: Timer = Timer.new()
onready var dia_auto_end_timer: Timer = Timer.new()


func _ready():
	if dialogue_box != null:
		dia_timer.one_shot = true
		dia_timer.connect("timeout", self, "dia_timer_fin")
		add_child(dia_timer)

		dia_auto_end_timer.one_shot = true
		dia_auto_end_timer.connect("timeout", self, "dia_auto_end_timer_fin")
		add_child(dia_auto_end_timer)

		dialogue_box.connect("dialogue_finished", self, "dia_finished")


func dia_start(dias: Array, di_auto_end = false):
	if dialogue_box != null:
		state = State.PROCESSING
		auto_end = di_auto_end
		dia_i = -1
		dialogues = dias
		dialogue_box.connect("dialogue_closed", self, "dia_closed")
		emit_signal("dialogue_started")
		dia_next()


func dia_next():
	dia_i += 1
	if dia_i < len(dialogues):
		dia_auto_end_timer.stop()

		dia_timer.stop()
		var time = dialogues[dia_i][2]
		dia_timer.start(time)
		
	else:
		emit_signal("dialogue_finished")
		dialogue_box.disconnect("dialogue_closed", self, "dia_closed")
		state = State.IDLE
		auto_end = false


func dia_closed():
	dia_next()


func dia_timer_fin():
	var name = dialogues[dia_i][0]
	var dia = dialogues[dia_i][1]
	emit_signal("dialogue_changed")
	dialogue_box.start_dialogue(name, dia)

	
func dia_finished():
	if auto_end:
		dia_auto_end_timer.stop()
		if len(dialogues[dia_i]) > 3:
			dia_auto_end_timer.start(dialogues[dia_i][3])
		else:
			dia_auto_end_timer.start(Global.dia_auto_end_time)


func dia_auto_end_timer_fin():
	dialogue_box.visible = false
	dialogue_box.char_time.stop()
	dia_next()


func is_processing():
	return state == State.PROCESSING