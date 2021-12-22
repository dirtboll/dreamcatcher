extends Control

signal dialogue_finished()
signal dialogue_skipped()
signal dialogue_closed()

var interactable = false

onready var char_time: Timer 	= $Timer
onready var dia_label: Label 	= $DialogueFrame/Dialogue
onready var name_label: Label 	= $NameFrame/Name

func _process(_delta):
	if Input.is_action_just_pressed("interact"):
		close_dialogue()

func close_dialogue():
	if interactable:
		if not char_time.is_stopped():
			char_time.stop()
			dia_label.visible_characters = len(dia_label.text)
			emit_signal("dialogue_skipped")
		elif self.visible:
			self.visible = false
			emit_signal("dialogue_closed")

func start_dialogue(di_name: String, dia: String):
	char_time.stop()
	
	self.visible = true

	dia_label.text = dia
	name_label.text = di_name
	dia_label.visible_characters = 0

	char_time.start(char_time.wait_time)

func _on_Timer_timeout():
	if dia_label.visible_characters < len(dia_label.text):
		dia_label.visible_characters += 1
	else:
		char_time.stop()
		emit_signal("dialogue_finished")
