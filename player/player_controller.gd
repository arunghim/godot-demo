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

@export_group("UI")
@export var inventory_ui: Control
@export var hotbar_ui: Control

var camera_input_direction := Vector2.ZERO
var last_movement_direction := Vector3.BACK
var gravity := -30.0

var is_dodging := false
var dodge_timer := 0.0
var dodge_direction := Vector3.ZERO
var dodge_move_duration := 0.8

var is_blocking := false
var attack_cooldown := 0.0
var inventory_open := false

@onready var camera_pivot: Node3D = %Pivot
@onready var camera: Camera3D = %Camera3D
@onready var mannequin_instance: Node3D = $Mannequin
@onready
var mannequin_animation_player: AnimationPlayer = mannequin_instance.get_node("AnimationPlayer")

var horizontal_velocity := Vector3.ZERO


func _ready() -> void:
	if inventory_ui:
		inventory_ui.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory") and inventory_ui:
		inventory_open = not inventory_open
		inventory_ui.visible = inventory_open
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if inventory_open else Input.MOUSE_MODE_CAPTURED
		return
	if inventory_open and event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if not inventory_open and event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		camera_input_direction = event.screen_relative * mouse_sensitivity


func _physics_process(delta: float) -> void:
	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	camera_pivot.rotation.x = clamp(
		camera_pivot.rotation.x + camera_input_direction.y * delta,
		tilt_lower_limit,
		tilt_upper_limit
	)
	camera_pivot.rotation.y -= camera_input_direction.x * delta
	camera_input_direction = Vector2.ZERO

	var can_act := (
		not inventory_open and attack_cooldown <= 0.0 and not is_blocking and not is_dodging
	)

	if can_act:
		if Input.is_action_just_pressed("primary_action"):
			mannequin_animation_player.play("Punch_Cross")
			attack_cooldown = mannequin_animation_player.current_animation_length + 0.1
		if Input.is_action_just_pressed("special_action"):
			mannequin_animation_player.play("Punch_Jab")
			attack_cooldown = mannequin_animation_player.current_animation_length + 0.1
		if Input.is_action_just_pressed("interact"):
			mannequin_animation_player.play("Spell_Simple_Exit")
			attack_cooldown = mannequin_animation_player.current_animation_length + 0.1
		if Input.is_action_just_pressed("dodge"):
			is_dodging = true
			is_blocking = false
			dodge_direction = last_movement_direction.normalized()
			if dodge_direction == Vector3.ZERO:
				dodge_direction = -camera.global_basis.z
				dodge_direction.y = 0.0
			mannequin_animation_player.play("Roll")
			dodge_timer = mannequin_animation_player.current_animation_length

	if Input.is_action_pressed("secondary_action") and not is_dodging and not inventory_open:
		if not is_blocking:
			is_blocking = true
			mannequin_animation_player.play("Punch_Enter")
			mannequin_animation_player.seek(
				mannequin_animation_player.current_animation_length, true
			)
	else:
		is_blocking = false

	var raw_input := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var forward := camera.global_basis.z
	var right := camera.global_basis.x
	var move_direction := forward * raw_input.y + right * raw_input.x
	move_direction.y = 0.0
	if move_direction.length() > 0.0:
		move_direction = move_direction.normalized()

	var is_sprinting := Input.is_action_pressed("sprint")
	var is_crouching := Input.is_action_pressed("crouch")
	var target_speed := move_speed
	if is_blocking or inventory_open:
		target_speed = crouch_speed
	elif is_sprinting:
		target_speed = sprint_speed
	elif is_crouching:
		target_speed = crouch_speed

	if is_dodging:
		var anim_length := mannequin_animation_player.current_animation_length
		var move_end_time := anim_length - dodge_move_duration
		horizontal_velocity = (
			dodge_direction * dodge_speed
			if dodge_timer > move_end_time
			else horizontal_velocity.move_toward(Vector3.ZERO, acceleration * delta * 4.0)
		)
		dodge_timer -= delta
		if dodge_timer <= 0.0:
			is_dodging = false
	elif move_direction.length() > 0.001:
		horizontal_velocity = horizontal_velocity.move_toward(
			move_direction * target_speed, acceleration * delta
		)
	else:
		horizontal_velocity = horizontal_velocity.move_toward(Vector3.ZERO, acceleration * delta)

	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z
	velocity.y += gravity * delta
	if Input.is_action_just_pressed("jump") and is_on_floor() and not inventory_open:
		velocity.y = jump_impulse

	move_and_slide()

	if move_direction.length() > 0.05:
		last_movement_direction = move_direction

	var target_rot := Vector3.BACK.signed_angle_to(last_movement_direction, Vector3.UP)
	mannequin_instance.rotation.y = lerp_angle(
		mannequin_instance.rotation.y, target_rot, rotation_speed * delta
	)

	var state := ""
	state = (
		"Dodging"
		if is_dodging
		else (
			"Blocking"
			if is_blocking
			else (
				"Jumping"
				if not is_on_floor() and velocity.y > 0
				else (
					"Falling"
					if not is_on_floor()
					else (
						"Crouching"
						if is_crouching
						else (
							"Sprinting"
							if move_direction.length() > 0.05 and is_sprinting
							else "Walking" if move_direction.length() > 0.05 else "Idle"
						)
					)
				)
			)
		)
	)

	match state:
		"Dodging":
			pass
		"Blocking":
			mannequin_animation_player.play("Punch_Enter")
			mannequin_animation_player.seek(
				mannequin_animation_player.current_animation_length, true
			)
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
	if dot_forward > 0.5:
		return "forwards"
	elif dot_forward < -0.5:
		return "backwards"
	elif dot_right > 0.5:
		return "right"
	elif dot_right < -0.5:
		return "left"
	return "straight"
