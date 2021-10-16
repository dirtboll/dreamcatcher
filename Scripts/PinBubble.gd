extends AnimatedSprite


var target_pin_node: Node2D = null
var target_node: Node2D = null
var ready = false
var margin = Vector2(10, 10)
export var range_min = 100
export var range_max = 400
export var range_vanish = 1000

onready var camera: Camera2D = get_node("../Camera2D")

onready var cam_edge = (get_viewport().size * camera.zoom) / 2
onready var max_pos = cam_edge - margin
onready var min_pos = -cam_edge + margin



func _process(_delta):
	if target_pin_node != null and target_node != null:		
		var pos = target_pin_node.global_position
		var clamp_pos_max = max_pos + camera.global_position
		var clamp_pos_min = min_pos + camera.global_position
		global_position = Vector2(clamp(pos.x, clamp_pos_min.x, clamp_pos_max.x), clamp(pos.y, clamp_pos_min.y, clamp_pos_max.y)) #

		var out_dist = (target_node.global_position - camera.global_position).length()
		var diff = range_max - range_min
		var rg_norm = out_dist - range_min
		var frame_index = int((diff - clamp(rg_norm, 0, diff))/float(diff) * 6)
		frame = frame_index
	else:
		visible = false


func set_target_pin(node: Node2D):
	if node != null:
		target_pin_node = node.get_node_or_null("PinPos")
		target_node = node
		visible = true
	else:
		target_node = null
		target_pin_node = null
		visible = false
