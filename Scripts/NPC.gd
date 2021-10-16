extends KinematicBody2D

signal target_reached()
signal interacted()

export var flipped = false

enum State {
	IDLE,
	WALKING,
}
var GRAVITY = 200
var speed = 25.0
var acceleration = 1000
var state = State.IDLE
var target = null
var velocity = Vector2.ZERO
var direction = 0

var interactable = false


onready var anim_sprite = $AnimatedSprite

func _ready():
	anim_sprite.flip_h = flipped

func _process(_delta):
	if state == State.WALKING:
		anim_sprite.play("Walk")
	elif state == State.IDLE:
		anim_sprite.play("Idle")

	if round(direction) == 1:
		anim_sprite.flip_h = false
	elif round(direction) == -1:
		anim_sprite.flip_h = true

func _physics_process(delta):

	velocity.y = velocity.y + delta * GRAVITY

	if state == State.WALKING:
		if target != null:
			if target.round().is_equal_approx(global_position.round()):
				stop_walk()
				emit_signal("target_reached")
			else:
				direction = (target - global_position).normalized().x
		else:
			stop_walk()
			
	
	velocity = velocity.move_toward(Vector2(direction * speed, velocity.y), acceleration * delta)
	velocity = move_and_slide(velocity)

func set_target(pos: Vector2):
	target = pos
	state = State.WALKING

func start_walk():
	state = State.WALKING

func stop_walk():
	state = State.IDLE
	direction = 0

func interact():
	if interactable:
		emit_signal("interacted")
