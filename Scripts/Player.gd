extends KinematicBody2D

export (int) var GRAVITY = 400

signal died()

var ready = false

#Inputs
var direction = Vector2()
var jumped = false	
var double_jumped = false

#Physics
var speed = 60
var acceleration = 20
var deacceleration = 20
var jump_speed = -200
var max_y = 150
var velocity = Vector2()

#Mechanic
var max_health = 100.0
var vignette_start = 30.0
var damage = 5.0
var atk_time = 1
var dash_speed = 200.0
var dash_time = 0.2
var dash_cds = 1
var hit_cds = 0.5
var wall_time = 3
var health = max_health
var atk_anim_num = 0
var on_wall = false
var wall_dir = 0
var cast_length = 0
var nearest_npc = null

onready var timer_atk: Timer = Timer.new()
onready var timer_dash: Timer = Timer.new()
onready var timer_dash_cd: Timer = Timer.new()
onready var timer_wall: Timer = Timer.new()
onready var timer_hit_cd: Timer = Timer.new()

#Animation
var prio_anim = ""

onready var anim_sprite:AnimatedSprite			= $AnimatedSprite
onready var anim_player:AnimationPlayer			= $AnimationPlayer
onready var attack_area:Area2D  				= $AttackArea
onready var main_coll: CollisionShape2D 		= $MainCollission
onready var platform_area: Area2D 				= $PlatformArea
onready var light								= $Light2D
onready var health_indicator: TextureRect 		= $Camera2D/HealthIndicator
onready var interact_area: Area2D				= $InterractArea
onready var ray_cast: RayCast2D 				= RayCast2D.new()
onready var pin_bubble_sign: AnimatedSprite  	= $PinBubble
onready var pin_bubble_sign_timer		  		= Timer.new()
onready var pin_bubble_npc: AnimatedSprite  	= $PinBubbleNPC
onready var pin_bubble_npc_refresh_timer: Timer	= Timer.new()
onready var camera								= $Camera2D

func _ready():
	timer_atk.one_shot = true
	timer_dash.one_shot = true
	timer_dash_cd.one_shot = true
	timer_hit_cd.one_shot = true
	timer_wall.one_shot = false
	pin_bubble_sign_timer.one_shot = true
	timer_wall.connect("timeout", self, "unwall")
	pin_bubble_sign_timer.connect("timeout", self, "pin_exit_fin")
	add_child(timer_atk)
	add_child(timer_dash)
	add_child(timer_dash_cd)
	add_child(timer_wall)
	add_child(ray_cast)
	add_child(timer_hit_cd)
	add_child(pin_bubble_sign_timer)
	cast_length = main_coll.shape.extents.x + 0.1
	ray_cast.position = main_coll.position
	ray_cast.position.y -= main_coll.shape.extents.y

	pin_bubble_npc_refresh_timer.connect("timeout", self, "_on_pin_bubble_npc_timeout")
	add_child(pin_bubble_npc_refresh_timer)
	pin_bubble_npc_refresh_timer.start(0.1)

	light.brighten()

func _process(_delta):
	if is_dead(): 
		return

	if jumped:
		play_prio_anim("Jump")
		anim_sprite.frame = 0

	if is_dashing():
		play_anim("Dash")
	elif velocity.y > 0 and not raycast_cast(Vector2(0, 24)):
		play_anim("Fall")
	elif abs(velocity.x) > 5 and is_on_floor():
		play_anim("Run")
	elif abs(velocity.x) <= 5 and is_on_floor():
		play_anim("Idle")
	elif on_wall:
		play_anim("Wall")

	if velocity.x > 0:
		flip(false)
	elif velocity.x < 0:
		flip(true)

	if Input.is_action_just_pressed("interact"):
		if nearest_npc != null:
			nearest_npc.interact()

		# var node = get_node_or_null("../EndArea")
		# if node != null:
		# 	global_position = node.global_position - Vector2(0,20)
			
	pin_bubble_npc.set_target_pin(nearest_npc)

	health_indicator.modulate.a = ((vignette_start - clamp(health, 1, vignette_start)) / vignette_start) * 0.5

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
	if is_dashing():
		horizontal_velocity = dash_speed * (int(not anim_sprite.flip_h) * 2 - 1)

	#Calculate Y velocity
	var vertical_velocity = velocity.y + delta * GRAVITY
	if jumped:
		vertical_velocity = jump_speed
	if jumped and on_wall:
		on_wall = false
		vertical_velocity = jump_speed
	elif is_dashing() or on_wall:
		vertical_velocity = 0
	vertical_velocity = clamp(vertical_velocity, -max_y, max_y)

	#Move
	velocity = move_and_slide(Vector2(horizontal_velocity, vertical_velocity), Vector2.UP)


func update_input():
	if is_on_floor():
		double_jumped = false

	#Calculate direction
	direction = Vector2()
	if Input.is_action_just_pressed('up'):
		if is_on_floor() or on_wall:
			jumped = true
		elif not double_jumped:
			jumped = true
			double_jumped = true
	else:
		jumped = false

	if not velocity.is_equal_approx(Vector2.ZERO):
		on_wall = false

	if Input.is_action_pressed('right'):
		direction.x = 1
	if Input.is_action_pressed('left'):
		direction.x = -1
	if Input.is_action_just_pressed("attack"):
		attack()
	if Input.is_action_just_pressed("dash"):
		on_wall = false
		if timer_dash_cd.time_left <= 0:
			timer_dash_cd.start(dash_cds)
			timer_dash.start(dash_time)
			direction.x = (int(not anim_sprite.flip_h) * 2 - 1)
	if (Input.is_action_pressed('left') or Input.is_action_pressed('right')) \
	and is_on_wall() \
	and get_wall_direction() != 0 \
	and not is_on_floor():
		wall()

	set_collision_mask_bit(1, not Input.is_action_pressed('down'))


func attack():
	unwall()
	if not "Attack" in prio_anim:
		attack_anim()
		var areas = attack_area.get_overlapping_areas()
		var attacked = []
		for area in areas:
			var entity = area.get_parent()
			entity.hit(damage, self)
			attacked.append(entity)

func attack_anim():
	if timer_atk.time_left <= 0:
		atk_anim_num = 3
	else:
		atk_anim_num += 1
	atk_anim_num %= 3
	timer_atk.start(atk_time)
	play_prio_anim("Attack"+str(atk_anim_num))

func hit(dmg, hitter):
	if is_dead() or timer_hit_cd.time_left > 0 or is_dashing():
		return
	
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

func get_wall_direction() -> int:
	var left = raycast_cast(Vector2(-cast_length,0))
	var right = raycast_cast(Vector2(cast_length,0))

	if left and right:
		return int(not anim_sprite.flip_h) * 2 - 1
	else:
		return -int(left) + int(right)

func raycast_cast(dir: Vector2) -> bool:
	ray_cast.cast_to = dir
	ray_cast.force_raycast_update()
	return ray_cast.is_colliding()

func wall():
	on_wall = true
	wall_dir = get_wall_direction()
	double_jumped = false
	timer_wall.start(wall_time)

func unwall():
	on_wall = false

func death():
	set_physics_process(false)
	play_prio_anim("Death")
	light.dim()
	light.connect("done", self, "after_death")

func after_death():
	emit_signal("died")
	light.energy = 1

func is_prio_anim():
	return prio_anim != ""

func is_dashing():
	return timer_dash.time_left > 0

func is_dead():
	return health <= 0

func flip(left: bool):
	anim_sprite.flip_h = left
	attack_area.position.x = (int(not left) * 2 - 1) * abs(attack_area.position.x)

func pin_exit():
	var exit = get_node_or_null("../EndArea")
	if exit != null:
		pin_bubble_sign.set_target_pin(exit)
		pin_bubble_sign_timer.start(5)

func pin_exit_fin():
	pin_bubble_sign.set_target_pin(null)


func brighten():
	var canvasmodulate = get_node_or_null("../CanvasModulate")
	if canvasmodulate != null:
		canvasmodulate.brighten()
		var timer = Timer.new()
		timer.one_shot = true
		add_child(timer)
		timer.start(8)
		timer.connect("timeout", self, "brighten_fin", [timer, canvasmodulate])

func brighten_fin(timer, canvasmodulate):
	timer.queue_free()
	canvasmodulate.dim()

