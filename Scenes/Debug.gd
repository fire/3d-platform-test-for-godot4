extends Label

@onready var _player: CharacterBody3D = owner.get_node("Player")

var _debug_dict: Dictionary = {}

func _process(_delta):
	var floor_v: Vector3 = _player.get_platform_velocity()
	_debug_dict.clear()
	if not Global.DRAW_HUD:
		text = ""
		return
	_debug_dict["Position"] =  "(%f, %f, %f)" % [_player.global_transform.origin.x, _player.global_transform.origin.y, _player.global_transform.origin.z]
	var speed_length = (_player.prev_position - _player.position + floor_v * get_physics_process_delta_time()).length()
	_debug_dict["Speed"] = snapped(speed_length * 100 , 0.001)
	
	_debug_dict["Velocity"] = "(%.2f, %.2f, %.2f) - Length %.3f" % [_player.linear_velocity.x, _player.linear_velocity.y, _player.linear_velocity.z, _player.linear_velocity.length()]
	var last_motion = _player.util_last_motion()
	var real_movement = _player.get_real_velocity()
	if last_motion:
		_debug_dict["Real Velocity"] = "(%.2f, %.2f, %.2f) - Length %.3f" % [real_movement.x, real_movement.y, real_movement.z, real_movement.length()]
		_debug_dict["Last Motion"] = "(%.2f, %.2f, %.2f) - Length %.3f" % [last_motion.x, last_motion.y, last_motion.z, last_motion.length()]
	else:
		_debug_dict["Real full motion"] = "N/A"
		_debug_dict["Last Motion"] = "N/A"
	
	_debug_dict["Platform Velocity"] = "(%.2f, %.2f, %.2f)" % [floor_v.x, floor_v.y, floor_v.z]
	
	_debug_dict["Is On Floor"] = _player.util_on_floor()
	_debug_dict["Is On Wall"] = _player.util_on_wall()
	
	_debug_dict["Floor Normal"] = str(_player.get_floor_normal()) if _player.get_floor_normal() != Vector3() else "N/A"
	_debug_dict["Wall Normal"] = str(_player.get_wall_normal()) if _player.get_wall_normal() != Vector3() else "N/A"
	
	_debug_dict["Slide count"] = _player.get_slide_collision_count()

	var last_col = _player.util_latest_collision() if Global.CURRENT_DEBUG_SLIDE == -1 else _player.get_slide_collision(Global.CURRENT_DEBUG_SLIDE)
	if last_col:
	
		var is_last = Global.CURRENT_DEBUG_SLIDE == -1 or Global.CURRENT_DEBUG_SLIDE == _player.get_slide_collision_count() -1
		var current_slide_index = _player.get_slide_collision_count() if is_last else (Global.CURRENT_DEBUG_SLIDE + 1)
		
		_debug_dict["--- Collision Details for the slide with index"] = str(current_slide_index) +  (" (last)" if is_last else "")
		_debug_dict["Collision count"] = last_col.get_collision_count()
		for i in last_col.get_collision_count():
			var _norm = "(%.2f, %.2f, %.2f)" % [last_col.get_normal(i).x, last_col.get_normal(i).y, last_col.get_normal(i).z]
			var _angle = ""
			if _player.motion_mode == 0:
				_angle = "%.2f°" % rad2deg(last_col.get_angle(i))
			else:
				_angle = "%.2f°" % rad2deg(acos(last_col.normal.dot(-_player.linear_velocity.normalized())))
			var _type = _player._debug_col_type(i, Global.CURRENT_DEBUG_SLIDE)
			_debug_dict["Col %d normal" % i  ] = str(_norm) + " - angle: " + str(_angle) + " - type : " + str(_type)
	text = ""
	for i in _debug_dict:
		text += str(i) + ": " + str(_debug_dict[i]) + "\n"
