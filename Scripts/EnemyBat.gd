extends KinematicBody2D

#Entity State
enum {
	IDLE,
	CHASE,
	ATTACK
}
var state = IDLE

#Physics
var speed = 75.0
var acceleration = 200.0
var velocity = Vector2()

#Mechanic
export (float) var health = 20.0
export (float) var damage = 5.0
export (int) var search_cd = 0.5
export (int) var attack_passive_cd = 1
var target_entity_area = null

#Animation
var prio_anim = ""
var attacked = false

onready var anim_sprite = $AnimatedSprite
onready var anim_player = $AnimationPlayer
onready var attack_area = $AttackArea
onready var attack_passive_area = $PassiveAttackArea
onready var detect_area = $DetectArea
onready var timer_search = Timer.new()
onready var timer_attack_passive = Timer.new()

onready var parent = get_parent()

func _ready():
	timer_search.one_shot = true
	timer_attack_passive.one_shot = true
	add_child(timer_search)
	add_child(timer_attack_passive)
	timer_search.start(search_cd)
	timer_attack_passive.start(attack_passive_cd)

func _process(_delta):
	if is_dead(): return

	play_anim("Fly")
			
	if velocity.x >= 0:
		anim_sprite.flip_h = true
		attack_area.position.x = abs(attack_area.position.x)
		attack_area.scale.x = abs(attack_area.scale.x)
	else:
		anim_sprite.flip_h = false
		attack_area.position.x = -abs(attack_area.position.x)
		attack_area.scale.x = -abs(attack_area.scale.x)
	
			
func _physics_process(delta):
	if is_dead(): return

	var direction = Vector2.ZERO
	if state == CHASE:
		if attack_area.overlaps_area(target_entity_area):
			state = ATTACK
		elif target_entity_area != null and !target_entity_area.get_parent().is_dead() and detect_area.overlaps_area(target_entity_area):
			direction = (target_entity_area.get_parent().global_position - attack_area.global_position).normalized()
		else:
			state = IDLE
	elif state == ATTACK:
		if attack_area.overlaps_area(target_entity_area):
			if anim_sprite.animation != "Attack":
				play_prio_anim("Attack")
		else:
			state = CHASE

		if anim_sprite.animation == "Attack" and anim_sprite.frame == 0 and not attacked:
			attack()
			attacked = true
		elif anim_sprite.frame != 0:
			attacked = false
	else:
		if timer_search.time_left <= 0:
			for area in detect_area.get_overlapping_areas():
				if "Player" in area.get_parent().get_name() and !area.get_parent().is_dead():
					target_entity_area = area
					state = CHASE			
			if target_entity_area == null:
				timer_search.start(search_cd)

	velocity = velocity.move_toward(direction * speed, acceleration * delta)
	velocity = move_and_slide(velocity)

	if timer_attack_passive.time_left <= 0:
		for area in attack_passive_area.get_overlapping_areas():
			area.get_parent().hit(damage, self)
			timer_attack_passive.start(attack_passive_cd)

func attack():
	if target_entity_area in attack_area.get_overlapping_areas():
		target_entity_area.get_parent().hit(damage, self)

func hit(dmg, hitter):
	if is_dead():
		return
		
	health -= dmg
	anim_player.play("Hit")
	if health <= 0:
		death()
	else:
		var is_right = position.x > hitter.position.x
		var dir = int(is_right) * 2 - 1
		velocity.x = dir * 50
		

func death():
	set_process(false)
	set_physics_process(false)
	play_prio_anim("Death")
	if "mob_num" in parent.get_property_list():
		parent.mob_num -= 1

func is_dead():
	return health <= 0

func is_prio_anim():
	return prio_anim != ""

func play_prio_anim(anim):
	prio_anim = anim
	anim_sprite.play(anim)

func play_anim(anim):
	if not is_prio_anim():
		anim_sprite.play(anim)

func _on_AnimatedSprite_animation_finished():
	if anim_sprite.animation == "Death":
		queue_free()
	elif anim_sprite.animation == prio_anim:
		prio_anim = ""