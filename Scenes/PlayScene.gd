extends Node3D


@onready var _player: CharacterBody3D = $Player
@onready var _debug_log: Label = $Texts/Debug
var _debug_dict: Dictionary = {
}

const SPEED_ARRAY_SIZE = 30
var _speed_array: Array = []
var _speed_average: float = 0.0
var before_player_pos: Vector3 = Vector3()
# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(SPEED_ARRAY_SIZE):
		_speed_array.append(0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	
	# Calc speed average
	var current_speed = (before_player_pos - _player.global_transform.origin).length()
	_speed_array.push_front(current_speed)
	before_player_pos = _player.global_transform.origin
	_speed_array.pop_back()
	_speed_average = 0
	for i in range(SPEED_ARRAY_SIZE):
		_speed_average += _speed_array[i]
	_speed_average / SPEED_ARRAY_SIZE
	_debug_dict["Position"] =  "(%f, %f, %f)" % [_player.global_transform.origin.x, _player.global_transform.origin.y, _player.global_transform.origin.z]
	_debug_dict["Speed"] = snapped(current_speed * 100, 0.001)
	_debug_dict["Average Speed"] = snapped(_speed_average, 0.001)
	_debug_dict["Velocity"] = "(%.2f, %.2f, %.2f)" % [_player.linear_velocity.x, _player.linear_velocity.y, _player.linear_velocity.z]
	var last_motion = _player.util_last_motion().normalized()
	if last_motion:
		_debug_dict["Last Motion"] = "(%.2f, %.2f, %.2f)" % [last_motion.x, last_motion.y, last_motion.z]
	else:
		_debug_dict["Last Motion"] = "N/A"
	var last_collision = _player.util_latest_collision()
	if last_collision:
		_debug_dict["Collision normal"] = "(%.2f, %.2f, %.2f)" % [last_collision.normal.x, last_collision.normal.y, last_collision.normal.z]
	else:
		_debug_dict["Collision normal"] = "N/A"
	var floor_v: Vector3 = _player.get_platform_velocity()
	_debug_dict["Platform Velocity"] = "(%.2f, %.2f, %.2f)" % [floor_v.x, floor_v.y, floor_v.z]
	
	_debug_dict["Is On Floor"] = _player.util_on_floor()
	_debug_dict["Is On Wall"] = _player.util_on_wall()
	
	if _player.debug_last_collision:
		_debug_dict["Collision angle"] = "%.2f°" % rad2deg(_player.debug_last_collision.get_angle(Vector3.UP))
	else:
		_debug_dict["Collision angle"] = "N/A"
	
	_debug_log.text = ""
	for i in _debug_dict:
		_debug_log.text += str(i) + ": " + str(_debug_dict[i]) + "\n"

func _on_AirFrictionButton_toggled(button_pressed):
	Global.APPLY_AIR_FRICTION = button_pressed
	
func _on_GDScriptButton_toggled(button_pressed):
	Global.USE_NATIVE_METHOD = not button_pressed

func _on_OnFloorButton_toggled(button_pressed):
	Global.FLOOR_BLOCK_ON_WALL = button_pressed

func _on_SnapButton_toggled(button_pressed):
	Global.APPLY_SNAP = button_pressed

func _on_ConstantSpeedButton_toggled(button_pressed):
	Global.FLOOR_CONSTANT_SPEED = button_pressed

func _on_AccelerationButton_toggled(button_pressed):
	Global.APPLY_ACCELERATION = button_pressed

func _on_MaxFloorAngleSlider_value_changed(value):
	$Texts/MaxFloorAngleLabel.text = "Floor max angle: %.0f°" % round(value) 
	Global.FLOOR_MAX_ANGLE = deg2rad(value)

func _on_WallMinAngleSlideSlider_value_changed(value):
	$Texts/WallMinAngleSlideLabel.text = "Min slide angle: %.0f°" % round(value)
	Global.WALL_MIN_SLIDE_ANGLE = deg2rad(value)

func _on_StopSlopeButton_toggled(button_pressed):
	Global.FLOOR_STOP_ON_SLOPE = button_pressed


func _on_CheckButton_toggled(button_pressed):
	Global.DRAW_DEBUG_LINE = button_pressed
