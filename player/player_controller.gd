extends CharacterBody3D
class_name PlayerController

@export_group("Movement")
@export var move_speed := 8.0
@export var sprint_speed := 14.0
@export var crouch_speed := 4.0
@export var acceleration := 20.0
@export var rotation_speed := 12.0
@export var jump_impulse := 12.0
@export var dodge_speed := 18.0

@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensitivity := 0.25
@export var tilt_upper_limit := PI / 3.0
@export var tilt_lower_limit := -PI / 8.0

var camera_input_direction := Vector2.ZERO
var last_movement_direction := Vector3.BACK
var gravity := -30.0

var is_dodging := false
var dodge_timer := 0.0
var dodge_direction := Vector3.ZERO
var dodge_move_duration := 0.80

var is_blocking := false
var attack_cooldown := 0.0


@onready var camera_pivot: Node3D = %Pivot
@onready var camera: Camera3D = %Camera3D
@onready var mannequin_instance: Node3D = $Mannequin
@onready var mannequin_animation_player: AnimationPlayer = mannequin_instance.get_node("AnimationPlayer")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		camera_input_direction = event.screen_relative * mouse_sensitivity

func _physics_process(delta: float) -> void:
	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	camera_pivot.rotation.x += camera_input_direction.y * delta
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, tilt_lower_limit, tilt_upper_limit)
	camera_pivot.rotation.y -= camera_input_direction.x * delta
	camera_input_direction = Vector2.ZERO

	if Input.is_action_pressed("secondary_action"):
		if not is_blocking and not is_dodging:
			is_blocking = true
			mannequin_animation_player.play("Punch_Enter")
			mannequin_animation_player.seek(mannequin_animation_player.current_animation_length, true)
	else:
		is_blocking = false

	if attack_cooldown <= 0.0 and not is_blocking and not is_dodging:
		if Input.is_action_just_pressed("primary_action"):
			mannequin_animation_player.play("Punch_Cross")
			attack_cooldown = mannequin_animation_player.current_animation_length + 0.01

		if Input.is_action_just_pressed("special_action"):
			mannequin_animation_player.play("Punch_Jab")
			attack_cooldown = mannequin_animation_player.current_animation_length + 0.01

	if not is_blocking and Input.is_action_just_pressed("interact") and attack_cooldown <= 0.0:
		mannequin_animation_player.play("Spell_Simple_Exit")
		attack_cooldown = mannequin_animation_player.current_animation_length + 0.1

	if not is_dodging and Input.is_action_just_pressed("dodge"):
		is_dodging = true
		is_blocking = false
		dodge_direction = last_movement_direction.normalized()
		if dodge_direction == Vector3.ZERO:
			dodge_direction = -camera.global_basis.z
		mannequin_animation_player.play("Roll")
		dodge_timer = mannequin_animation_player.current_animation_length

	var is_sprinting := Input.is_action_pressed("sprint")
	var is_crouching := Input.is_action_pressed("crouch")

	var current_speed := move_speed
	if is_blocking:
		current_speed = crouch_speed
	elif is_sprinting:
		current_speed = sprint_speed
	elif is_crouching:
		current_speed = crouch_speed

	var raw_input := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var forward := camera.global_basis.z
	var right := camera.global_basis.x
	var move_direction := (forward * raw_input.y + right * raw_input.x).normalized()
	move_direction.y = 0.0

	velocity.y += gravity * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_impulse

	var horizontal_velocity := velocity
	horizontal_velocity.y = 0.0

	if is_dodging:
		var anim_length := mannequin_animation_player.current_animation_length
		var move_end_time := anim_length - dodge_move_duration
		if dodge_timer > move_end_time:
			horizontal_velocity = dodge_direction * dodge_speed
		else:
			horizontal_velocity = Vector3.ZERO
		dodge_timer -= delta
		if dodge_timer <= 0.0:
			is_dodging = false
	elif move_direction.length() > 0.0:
		horizontal_velocity = horizontal_velocity.move_toward(move_direction * current_speed, acceleration * delta)
	else:
		horizontal_velocity = Vector3.ZERO

	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z

	move_and_slide()

	if move_direction.length() > 0.05:
		last_movement_direction = move_direction

	var target_angle := Vector3.BACK.signed_angle_to(last_movement_direction, Vector3.UP)
	mannequin_instance.rotation.y = lerp_angle(mannequin_instance.rotation.y, target_angle, rotation_speed * delta)

	var state := ""
	if is_dodging:
		state = "Dodging"
	elif is_blocking:
		state = "Blocking"
	elif not is_on_floor():
		if velocity.y > 0.0: state = "Jumping"
		else: state = "Falling"
	elif is_crouching:
		state = "Crouching"
	elif move_direction.length() > 0.05:
		if is_sprinting: state = "Sprinting"
		else: state = "Walking"
	else:
		state = "Idle"

	match state:
		"Dodging":
			pass
		"Blocking":
			mannequin_animation_player.play("Punch_Enter")
			mannequin_animation_player.seek(mannequin_animation_player.current_animation_length, true)
		"Jumping":
			if attack_cooldown <= 0.0:
				mannequin_animation_player.play("Jump")
		"Falling":
			if attack_cooldown <= 0.0:
				mannequin_animation_player.play("Jump")
		"Sprinting":
			if attack_cooldown <= 0.0 and not is_blocking:
				mannequin_animation_player.play("Sprint")
		"Walking":
			if attack_cooldown <= 0.0 and not is_blocking:
				mannequin_animation_player.play("Walk")
		"Crouching":
			if attack_cooldown <= 0.0 and not is_blocking:
				if move_direction.length() > 0.0:
					mannequin_animation_player.play("Crouch_Fwd")
				else:
					mannequin_animation_player.play("Crouch_Idle")
		_:
			if attack_cooldown <= 0.0 and not is_blocking and not is_dodging:
				mannequin_animation_player.play("Idle")


func _get_move_direction_name(direction: Vector3) -> String:
	var forward := camera.global_transform.basis.z
	var right := camera.global_transform.basis.x
	var dot_forward := direction.dot(-forward)
	var dot_right := direction.dot(right)
	if dot_forward > 0.5: return "forwards"
	elif dot_forward < -0.5: return "backwards"
	elif dot_right > 0.5: return "right"
	elif dot_right < -0.5: return "left"
	return "straight"
