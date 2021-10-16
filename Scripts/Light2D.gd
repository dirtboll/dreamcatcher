extends Light2D

signal done()

var timer: Timer = Timer.new()
var dimming = false

func _ready():
	timer.one_shot = true
	add_child(timer)
	timer.connect("timeout", self, "timer_fin")

func _process(_delta):
	if timer.time_left > 0:
		var start = int(not dimming) * 1 
		var target = int(dimming) * 1
		energy = start + (target - start) * (timer.time_left / timer.wait_time)

func brighten():
	dimming = false
	timer.start(2)

func dim():
	dimming = true
	timer.start(2)

func timer_fin():
	emit_signal("done")