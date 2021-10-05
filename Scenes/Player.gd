extends CharacterBody3D

@onready var camera := $Camera3D
var prev_position = Vector3()
var speed = 30
var turn_speed = 1 
var pitch_speed = 1

var turn_input = 0
var pitch_input = 0

func _process(_delta):
	wall_min_slide_angle = Global.WALL_MIN_SLIDE_ANGLE

func _physics_process(delta):
	prev_position = position
	_get_input()
	transform.basis = transform.basis.rotated(transform.basis.x, pitch_input * pitch_speed * delta)
	transform.basis = transform.basis.rotated(Vector3.UP, turn_input * turn_speed * delta)
	motion_velocity = -transform.basis.z * speed
	move_and_slide()
	
func _get_input():
	turn_input = int(Input.is_action_pressed("ui_left")) - int(Input.is_action_pressed("ui_right"))
	pitch_input = int(Input.is_action_pressed("ui_up")) - int(Input.is_action_pressed("ui_down"))

func util_last_motion():
	return get_last_motion()

func util_latest_collision():
	return get_last_slide_collision()

func util_on_floor():
	return is_on_floor()

func util_on_wall():
	return is_on_wall()

func util_on_floor_only():
	return is_on_floor_only()

func util_on_wall_only():
	return is_on_wall_only()

func _debug_col_type(i, slide = -1):
	return "wall"
