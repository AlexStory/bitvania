extends KinematicBody2D

const DustEffect = preload("res://Effects/DustEffect.tscn")
const PlayerBullet = preload("res://Player/PlayerBullet.tscn")
const JumpEffect = preload("res://Effects/JumpEffect.tscn")

var PlayerStats = ResLoader.PlayerStats

export(int) var ACCELERATION = 512
export(int) var MAX_SPEED = 64
export(float) var FRICTION = 0.25
export(int) var GRAVITY = 200
export(int) var JUMP_FORCE = 128
export(int) var MAX_SLOPE_ANGLE = 46
export(int) var BULLET_SPEED = 250

var motion := Vector2.ZERO
var snap_vector := Vector2.ZERO
var just_jumped := false
var jump_queued := false
var invincible := false setget set_invincible

onready var sprite := $Sprite
onready var sprite_animator := $SpriteAnimator
onready var blink_animator := $BlinkAnimator
onready var coyote_jump_timer := $CoyoteJumpTimer
onready var gun := $Sprite/PlayerGun
onready var muzzle := $Sprite/PlayerGun/Sprite/Muzzle
onready var fire_bullet_timer := $FireBulletTimer


func _ready() -> void:
	PlayerStats.connect("player_died", self, "_on_died")


func _physics_process(delta) -> void:
	just_jumped = false
	var input_vector := get_input_vector()
	apply_horizontal_force(input_vector, delta)
	apply_friction(input_vector)
	update_snap_vector()
	jump_check()
	apply_gravity(delta)
	update_animations(input_vector)
	move()
	fire_bullet()


func fire_bullet() -> void:
	if Input.is_action_pressed("action_fire") and fire_bullet_timer.time_left == 0:
		var bullet = Utils.instance_scene_on_main(PlayerBullet, muzzle.global_position)
		bullet.velocity = Vector2.RIGHT.rotated(gun.rotation) * BULLET_SPEED
		bullet.velocity.x *= sprite.scale.x
		bullet.rotation = bullet.velocity.angle()
		fire_bullet_timer.start()

func create_dust_effect():
	var dust_position = global_position
	dust_position.x += rand_range(-4, 4)
	var _dust_effect = Utils.instance_scene_on_main(DustEffect, dust_position)


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


func update_snap_vector():
	if is_on_floor():
		snap_vector = Vector2.DOWN


func initiate_jump() -> bool:
	return (is_on_floor() or coyote_jump_timer.time_left > 0) and Input.is_action_just_pressed("action_jump")


func jump_check() -> void:
	if initiate_jump() or jump_queued:
		apply_jump_force()
	if Input.is_action_just_released("action_jump") and motion.y < -JUMP_FORCE / 2:
		motion.y = -JUMP_FORCE / 2


func apply_jump_force() -> void:
	motion.y = -JUMP_FORCE
	snap_vector = Vector2.ZERO
	just_jumped = true
	jump_queued = false
	Utils.instance_scene_on_main(JumpEffect, global_position)


func apply_gravity(delta: float):
	if not is_on_floor():
		motion.y += GRAVITY * delta
		motion.y = min(motion.y, JUMP_FORCE)


func update_animations(input_vector: Vector2):
	sprite.scale.x = sign(get_local_mouse_position().x)
	
	if input_vector.x != 0:
		sprite_animator.play("Run")
		sprite_animator.playback_speed = sprite.scale.x * input_vector.x
	else:
		sprite_animator.play("Idle")
		sprite_animator.playback_speed = 1
	if !is_on_floor():
		sprite_animator.play("Jump")

func move():
	var was_on_flor = is_on_floor()
	var was_in_air = !is_on_floor()
	var last_position = position
	var last_motion = motion
	motion = move_and_slide_with_snap(motion, snap_vector * 4, Vector2.UP, true)
	
	# just left ground
	if was_on_flor and !is_on_floor() and !just_jumped:
		motion.y = 0
		position.y = last_position.y
		coyote_jump_timer.start()
	
	# just landed
	if was_in_air and is_on_floor():
		motion.x = last_motion.x
		create_dust_effect()
		
		if Input.is_action_pressed("action_jump"):
			jump_queued = true
			
	# TODO: Not hack
	if is_on_floor() and get_floor_velocity().length() == 0 and abs(motion.x) < 1:
		position.x = last_position.x


func _on_died() -> void:
	queue_free()


func _on_Hurtbox_hit(damage):
	PlayerStats.health -= damage
	
	if not invincible:
		blink_animator.play("Blink")


func set_invincible(value: bool) -> void:
	invincible = value
