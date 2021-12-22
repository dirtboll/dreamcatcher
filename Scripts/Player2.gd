extends KinematicBody2D

export (int) var GRAVITY = 400

var ready = false

#Inputs
var direction = Vector2()
var jumped = false	

#Physics
var speed = 100
var acceleration = 20
var deacceleration = 100
var vignette_start = 30.0
var jump_speed = -200
var max_y = 150
var velocity = Vector2()

#Mechanic
var max_health = 100.0
var hit_cds = 0.5
var wall_time = 3
var health = max_health
var nearest_npc = null

onready var timer_atk: Timer = Timer.new()
onready var timer_hit_cd: Timer = Timer.new()

#Animation
var prio_anim = ""

onready var anim_sprite:AnimatedSprite		= $AnimatedSprite
onready var anim_player:AnimationPlayer		= $AnimationPlayer
onready var color_rect 						= $Player2Rect
onready var main_coll: CollisionShape2D 	= $MainCollission
onready var health_indicator: TextureRect 	= $Camera2D/HealthIndicator
onready var interact_area: Area2D			= $InterractArea
onready var pin_bubble_npc: AnimatedSprite  = $PinBubbleNPC
onready var camera							:= $Camera2D
onready var pin_bubble_npc_refresh_timer: Timer	= Timer.new()

func _ready():
	timer_atk.one_shot = true
	timer_hit_cd.one_shot = true
	add_child(timer_atk)
	add_child(timer_hit_cd)

	pin_bubble_npc_refresh_timer.connect("timeout", self, "_on_pin_bubble_npc_timeout")
	add_child(pin_bubble_npc_refresh_timer)
	pin_bubble_npc_refresh_timer.start(0.1)

	color_rect.brighten()


func _process(_delta):
	if is_dead(): 
		return
	
	if abs(velocity.x) > 10 and is_on_floor():
		play_anim("Run")
	elif abs(velocity.x) <= 10 and is_on_floor():
		play_anim("Idle")

	if Input.is_action_just_pressed("interact"):
		if nearest_npc != null:
			nearest_npc.interact()

	pin_bubble_npc.set_target_pin(nearest_npc)

	health_indicator.modulate.a = ((vignette_start - clamp(health, 1, vignette_start)) / vignette_start) * 0.4


func _physics_process(delta):
	update_input()
	
	#If not moving, deaccelerate
	var acc = 0
	if direction.x != 0:
		acc = acceleration
	elif is_on_floor() or (not is_on_floor() and abs(velocity.x) > speed): #or not (is_dashing() or is_on_floor() or velocity.x > speed):
		acc = deacceleration
	else:
		acc = deacceleration/4 	

	#Calculate X velocity
	var targetX = Vector2(direction.x * speed, 0)
	var horizontal_velocity = velocity.x
	horizontal_velocity = Vector2(horizontal_velocity, 0).linear_interpolate(targetX, acc * delta).x

	var vertical_velocity = velocity.y + delta * GRAVITY

	#Move
	velocity = move_and_slide(Vector2(horizontal_velocity, vertical_velocity), Vector2.UP)


func update_input():
	#Calculate direction
	direction = Vector2()

	if Input.is_action_pressed('right'):
		direction.x = 1
	if Input.is_action_pressed('left'):
		direction.x = -1

	if direction.x > 0:
		flip(false)
	elif direction.x < 0:
		flip(true)

	set_collision_mask_bit(1, not Input.is_action_pressed('down'))


func hit(dmg, hitter):
	health -= dmg
	anim_player.play("Hit")
	if health <= 0:
		death()
	else:
		var is_right = position.x > hitter.position.x
		var dir = int(is_right) * 2 - 1
		velocity.x = dir * 100
		velocity.y = -100
		timer_hit_cd.start(hit_cds)


func play_prio_anim(anim):
	prio_anim = anim
	anim_sprite.play(anim)


func play_anim(anim):
	if not is_prio_anim():
		anim_sprite.play(anim)


func _on_AnimatedSprite_animation_finished():
	if anim_sprite.animation == "Death":
		pass
		#queue_free()
	elif anim_sprite.animation == prio_anim:
		prio_anim = ""


func _on_pin_bubble_npc_timeout():
	var bodies = interact_area.get_overlapping_bodies()
	if len(bodies) > 0:
		nearest_npc = bodies[0]
		if not nearest_npc.interactable:
			nearest_npc = null
	else:
		nearest_npc = null

func is_prio_anim():
	return prio_anim != ""


func is_dead():
	return health <= 0


func death():
	set_physics_process(false)
	#play_prio_anim("Death")


func flip(left: bool):
	anim_sprite.flip_h = left
