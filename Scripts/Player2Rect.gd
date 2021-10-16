extends ColorRect

var timer: Timer = Timer.new()
var dimming = false

func _ready():
	timer.one_shot = true
	add_child(timer)

func _process(_delta):
	if timer.time_left > 0:
		var start = int(dimming) * 1 
		var target = int(not dimming) * 1
		color.a = start + (target - start) * (timer.time_left / timer.wait_time)

func brighten():
	dimming = false
	timer.start(1)

func dim():
	dimming = true
	timer.start(1)