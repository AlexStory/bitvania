extends KinematicBody2D
class_name Player

const DustEffect = preload("res://Effects/DustEffect.tscn")
const PlayerBullet = preload("res://Player/PlayerBullet.tscn")
const JumpEffect = preload("res://Effects/JumpEffect.tscn")
const WallDustEffect = preload("res://Effects/WallSlideEffect.tscn")

var PlayerStats = ResLoader.PlayerStats
var MainInstances = ResLoader.MainInstances

export(int) var ACCELERATION = 512
export(int) var MAX_SPEED = 64
export(int) var WALL_SLIDE_SPEED = 48
export(int) var MAX_WALL_SLIDE_SPEED = 128
export(float) var FRICTION = 0.25
export(int) var GRAVITY = 200
export(int) var JUMP_FORCE = 128
export(int) var MAX_SLOPE_ANGLE = 46
export(int) var BULLET_SPEED = 250

enum {
	MOVE,
	WALL_SLIDE
} 

var state = MOVE
var motion := Vector2.ZERO
var snap_vector := Vector2.ZERO
var just_jumped := false
var jump_queued := false
var invincible := false setget set_invincible
var double_jump := true

onready var sprite := $Sprite
onready var sprite_animator := $SpriteAnimator
onready var blink_animator := $BlinkAnimator
onready var coyote_jump_timer := $CoyoteJumpTimer
onready var gun := $Sprite/PlayerGun
onready var muzzle := $Sprite/PlayerGun/Sprite/Muzzle
onready var fire_bullet_timer := $FireBulletTimer


func _ready() -> void:
	PlayerStats.connect("player_died", self, "_on_died")
	MainInstances.Player = self


func _exit_tree() -> void:
	MainInstances.Player = null


func _physics_process(delta: float) -> void:
	just_jumped = false
	match state:
		MOVE:
			var input_vector := get_input_vector()
			apply_horizontal_force(input_vector, delta)
			apply_friction(input_vector)
			update_snap_vector()
			jump_check()
			apply_gravity(delta)
			update_animations(input_vector)
			move()
			wall_slide_check()
		WALL_SLIDE:
			sprite_animator.play("WallSlide")
			var wall_axis = get_wall_axis()
			if wall_axis != 0:
				sprite.scale.x = wall_axis
			wall_slide_jump_check(wall_axis)
			wall_drop_check(delta)
			move()
			wall_detach_check(wall_axis, delta)
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
		apply_jump_force(JUMP_FORCE)
	if Input.is_action_just_released("action_jump") and motion.y < -JUMP_FORCE / 2:
		motion.y = -JUMP_FORCE / 2
	if Input.is_action_just_pressed("action_jump") and double_jump and !is_on_floor():
		double_jump = false
		apply_jump_force(JUMP_FORCE * .75)

func apply_jump_force(jump_force: float) -> void:
	motion.y = -jump_force
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
	var was_on_floor = is_on_floor()
	var was_in_air = !is_on_floor()
	var last_position = position
	var last_motion = motion
	motion = move_and_slide_with_snap(motion, snap_vector * 4, Vector2.UP, true, 4, deg2rad(MAX_SLOPE_ANGLE))
	
	# just left ground
	if was_on_floor and !is_on_floor() and !just_jumped:
		motion.y = 0
		position.y = last_position.y
		coyote_jump_timer.start()
	
	# just landed
	if was_in_air and is_on_floor():
		motion.x = last_motion.x
		create_dust_effect()
		double_jump = true
		
		if Input.is_action_pressed("action_jump"):
			jump_queued = true
			
	# TODO: Not hack
	if is_on_floor() and get_floor_velocity().length() == 0 and abs(motion.x) < 1:
		position.x = last_position.x


func wall_slide_check():
	if !is_on_floor() and is_on_wall():
		state = WALL_SLIDE
		double_jump = true
		create_dust_effect()


func get_wall_axis() -> int:
	var is_right_wall := test_move(transform, Vector2.RIGHT)
	var is_left_wall := test_move(transform, Vector2.LEFT)
	return int(is_left_wall) - int(is_right_wall)


func wall_slide_jump_check(wall_axis: int) -> void:
	if Input.is_action_just_pressed("action_jump"):
		motion.x = wall_axis * MAX_SPEED
		motion.y = -JUMP_FORCE / 1.25
		state = MOVE
		
		var dust_position = global_position + Vector2(wall_axis * 4, -4)
		var dust_effect = Utils.instance_scene_on_main(WallDustEffect, dust_position)
		dust_effect.scale.x = wall_axis

func wall_drop_check(delta: float):
	var max_slide_speed = WALL_SLIDE_SPEED
	if Input.is_action_pressed("ui_down"):
		max_slide_speed = MAX_WALL_SLIDE_SPEED
	motion.y = min(motion.y + GRAVITY * delta, max_slide_speed)


func wall_detach_check(wall_axis: int, delta: float) -> void:
	if wall_axis == 0 or is_on_floor():
		state = MOVE
		
	if Input.is_action_just_pressed("ui_right"):
		motion.x = ACCELERATION * delta
		state = MOVE
	
	if Input.is_action_just_pressed("ui_left"):
		motion.x = -ACCELERATION * delta
		state = MOVE


func _on_died() -> void:
	queue_free()


func _on_Hurtbox_hit(damage):
	PlayerStats.health -= damage
	
	if not invincible:
		blink_animator.play("Blink")


func set_invincible(value: bool) -> void:
	invincible = value
