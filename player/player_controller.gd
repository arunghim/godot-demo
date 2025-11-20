extends CharacterBody3D
class_name PlayerController

@export_group("Movement")
@export var move_speed := 8.0
@export var sprint_speed := 14.0
@export var crouch_speed := 4.0
@export var acceleration := 20.0
@export var rotation_speed := 12.0
@export var jump_impulse := 12.0

@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensitivity := 0.25
@export var tilt_upper_limit := PI / 3.0
@export var tilt_lower_limit := -PI / 8.0

var camera_input_direction := Vector2.ZERO
var last_movement_direction := Vector3.BACK
var gravity := -30.0

@onready var camera_pivot: Node3D = %Pivot
@onready var camera: Camera3D = %Camera3D

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed("left_click"): Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	var is_camera_motion := event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if is_camera_motion: camera_input_direction = event.screen_relative * mouse_sensitivity

func _physics_process(delta: float) -> void:
	camera_pivot.rotation.x += camera_input_direction.y * delta
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, tilt_lower_limit, tilt_upper_limit)
	camera_pivot.rotation.y -= camera_input_direction.x * delta
	camera_input_direction = Vector2.ZERO

	var is_sprinting := Input.is_action_pressed("sprint")
	var is_crouching := Input.is_action_pressed("crouch")
	var current_speed := move_speed

	if is_sprinting: current_speed = sprint_speed
	elif is_crouching: current_speed = crouch_speed

	var raw_input := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var forward := camera.global_basis.z
	var right := camera.global_basis.x

	var move_direction := forward * raw_input.y + right * raw_input.x
	move_direction.y = 0.0
	move_direction = move_direction.normalized()

	var y_velocity := velocity.y
	velocity.y = 0.0
	velocity = velocity.move_toward(move_direction * current_speed, acceleration * delta)
	velocity.y = y_velocity + gravity * delta

	var is_jumping := Input.is_action_just_pressed("jump") and is_on_floor()
	if is_jumping: velocity.y += jump_impulse

	move_and_slide()

	if move_direction.length() > 0.2: last_movement_direction = move_direction
