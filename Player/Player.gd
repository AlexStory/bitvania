extends KinematicBody2D

export(int) var ACCELERATION = 512
export(int) var MAX_SPEED = 64
export(float) var FRICTION = 0.25
export(int) var GRAVITY = 200
export(int) var JUMP_FORCE = 128
export(int) var MAX_SLOPE_ANGLE = 46

var motion := Vector2.ZERO

onready var sprite := $Sprite
onready var sprite_animator := $SpriteAnimator


func _physics_process(delta) -> void:
	var input_vector := get_input_vector()
	
	apply_horizontal_force(input_vector, delta)
	apply_friction(input_vector)
	jump_check()
	apply_gravity(delta)
	update_animations(input_vector)
	move()


func get_input_vector() -> Vector2:
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	return input_vector


func apply_horizontal_force(input_vector: Vector2, delta: float) -> void:
	if input_vector.x != 0:
		motion.x += input_vector.x * ACCELERATION * delta
		motion.x = clamp(motion.x, -MAX_SPEED, MAX_SPEED)


func apply_friction(input_vector: Vector2) -> void:
	if input_vector.x == 0 and is_on_floor():
		motion.x = lerp(motion.x, 0, FRICTION)


func jump_check():
	if is_on_floor() and Input.is_action_just_pressed("ui_up"):
		motion.y = -JUMP_FORCE
	if Input.is_action_just_released("ui_up") and motion.y < -JUMP_FORCE / 2:
		motion.y = -JUMP_FORCE / 2
		

func apply_gravity(delta: float):
	#if not is_on_floor():
		motion.y += GRAVITY * delta
		motion.y = min(motion.y, JUMP_FORCE)


func update_animations(input_vector: Vector2):
	if input_vector.x != 0:
		sprite.scale.x = sign(input_vector.x)
		sprite_animator.play("Run")
	else:
		sprite_animator.play("Idle")
	if !is_on_floor():
		sprite_animator.play("Jump")

func move():
	motion = move_and_slide(motion, Vector2.UP)

