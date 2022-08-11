extends CharacterBody3D
@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/SpringArm3D/Camera3D

var prev_position = Vector3()
var mouse_sensitivity: float = 0.0005
# Debug
var debug_last_collision: KinematicCollision3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if Input.is_action_just_pressed("reset"):
		position = Vector3(0,1,0)
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if event is InputEventMouseMotion:
		rotation.y = rotation.y - (event.relative.x * mouse_sensitivity)
		camera_pivot.rotation.x = camera_pivot.rotation.x + (event.relative.y * mouse_sensitivity )
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg2rad(-50), deg2rad(5))
	
	if Input.is_action_just_pressed("center"):
		rotation.y = snapped(rotation.y, deg2rad(90))

func _process(_delta):
	floor_block_on_wall = Global.FLOOR_BLOCK_ON_WALL
	floor_constant_speed = Global.FLOOR_CONSTANT_SPEED
	floor_max_angle = Global.FLOOR_MAX_ANGLE
	floor_stop_on_slope = Global.FLOOR_STOP_ON_SLOPE
	floor_snap_length = Global.SNAP_LENGTH 
	slide_on_ceiling = Global.SLIDE_ON_CEILING
	wall_min_slide_angle = Global.WALL_MIN_SLIDE_ANGLE
	up_direction = Global.UP_DIRECTION

func _physics_process(delta):
	prev_position = position
	var direction = Vector3()
	if Input.is_action_pressed("move_forward"):
		direction -= transform.basis.z
	if Input.is_action_pressed("move_backward"):
		direction += transform.basis.z
	if Input.is_action_pressed("move_left"):
		direction -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		direction += transform.basis.x

	direction = direction.normalized()
	
	var accel = Global.GROUND_ACCELERATION if util_on_floor() else Global.AIR_ACCELERATION
	var speed = Global.RUN_SPEED if Input.is_action_pressed("run") else Global.WALK_SPEED
	if (util_on_floor() and not Global.APPLY_ACCELERATION) or (not util_on_floor() and not Global.APPLY_ACCELERATION):
		if(util_on_floor() or Global.APPLY_AIR_FRICTION):
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
	else:
		if(util_on_floor() or Global.APPLY_AIR_FRICTION):
			velocity.x = lerp(velocity.x, direction.x * speed, accel * delta)
			velocity.z = lerp(velocity.z, direction.z * speed, accel * delta)
	
	if not util_on_floor():
		velocity.y = velocity.y - Global.GRAVITY
	
	if Input.is_action_just_pressed("jump"):
		if Global.INFINITE_JUMP or util_on_floor():
			velocity.y = Global.JUMP_FORCE
			floor_snap_length = 0
	
	#if Global.USE_NATIVE_METHOD:
	move_and_slide()
	#else:
#		custom_move_and_slide()	

class CustomKinematicCollision3D:
	var position : Vector3
	var normal : Vector3
	var collider : Object
	var collider_velocity : Vector3
	var travel : Vector3
	var remainder : Vector3
	var collision_rid: RID
	
	func get_angle(p_up_direction: Vector3) -> float:
		return acos(normal.dot(p_up_direction))
		
	func get_collider_rid():
		return collision_rid

func custom_move_and_collide(p_motion: Vector3, p_test_only: bool = false, p_cancel_sliding: bool = true, exlude = []):
	var gt := get_global_transform()

	var margin = get_safe_margin()
	
	var params := PhysicsTestMotionParameters3D.new()
	params.from = gt
	params.motion = p_motion
	params.margin = margin
	params.exclude_bodies = exlude

	var result := PhysicsTestMotionResult3D.new()
	var colliding := PhysicsServer3D.body_test_motion(get_rid(), params, result)

	var result_motion := result.get_travel()
	var result_remainder := result.get_remainder()

	if p_cancel_sliding:

		var motion_length := p_motion.length()
		var precision := 0.001

		if colliding:
			# Can't just use margin as a threshold because collision depth is calculated on unsafe motion,
			# so even in normal resting cases the depth can be a bit more than the margin.
			precision = precision + motion_length * (result.unsafe_fraction - result.safe_fraction)

			if result.get_collision_depth(0) > margin + precision:
				p_cancel_sliding = false

		if p_cancel_sliding:
			# When motion is null, recovery is the resulting motion.
			var motion_normal = Vector3.ZERO
			if motion_length > 0.00001:
				motion_normal = p_motion / motion_length

			# Check depth of recovery.
			var projected_length := result.get_travel().dot(motion_normal)
			var recovery = result.get_travel() - motion_normal * projected_length
			var recovery_length = recovery.length()
			# Fixes cases where canceling slide causes the motion to go too deep into the ground,
			# Becauses we're only taking rest information into account and not general recovery.
			if recovery_length < margin + precision:
				# Apply adjustment to motion.
				result_motion = motion_normal * projected_length
				result_remainder = p_motion - result_motion

	if (not p_test_only):
		position = position + result_motion

	if colliding:
		var collision := CustomKinematicCollision3D.new()
		collision.position = result.collision_point
		collision.normal = result.collision_normal
		collision.collider = result.collider
		collision.collider_velocity = result.collider_velocity
		collision.travel = result_motion
		collision.remainder = result_remainder
		collision.collision_rid = result.collider_rid

		return collision
	else:
		return null
		
# Debug
var debug_top_down_angle:= 0.0
var debug_last_normal = Vector3.ZERO
var debug_last_motion = Vector3.ZERO
var debug_auto_move := false
var use_build_in := false

var on_floor := false
var platform_rid :=  RID()
var platform_layer:int
var on_ceiling := false
var on_wall = false
var floor_normal := Vector3.ZERO
var platform_velocity := Vector3.ZERO
var FLOOR_ANGLE_THRESHOLD := 0.01
var was_on_floor = false

func custom_move_and_slide():
	var current_platform_velocity = platform_velocity
	if (on_floor or on_wall) and platform_rid.get_id():
		var excluded = false
		if on_floor:
			excluded = (moving_platform_floor_layers & platform_layer) == 0
		elif on_wall:
			excluded = (moving_platform_wall_layers & platform_layer) == 0
		if not excluded:
			var bs := PhysicsServer3D.body_get_direct_state(platform_rid)
			if bs:
				current_platform_velocity = bs.velocity
		else:
			current_platform_velocity = Vector3.ZERO

	was_on_floor = on_floor
	on_floor = false
	on_ceiling = false
	on_wall = false

	if not current_platform_velocity.is_equal_approx(Vector3.ZERO): # apply platform movement first
		custom_move_and_collide(current_platform_velocity * get_physics_process_delta_time(), false, false, [platform_rid])
#	emit_signal("follow_platform", str(current_platform_velocity * get_physics_process_delta_time()))
	#else:
	#	emit_signal("follow_platform", "/")

	if motion_mode == 0:
		_move_and_slide_grounded(current_platform_velocity)
	else:
		_move_and_slide_free()
	
	if not on_floor and not on_wall:
		velocity = velocity + current_platform_velocity # Add last floor velocity when just left a moving platform

func _move_and_slide_free():
	var motion = velocity * get_physics_process_delta_time()
		
	platform_rid = RID()
	floor_normal = Vector3.ZERO
	platform_velocity = Vector3.ZERO
	
	var first_slide = true
	for _i in range(max_slides):
		var collision = custom_move_and_collide(motion, false, false)
		if collision:
			_set_collision_direction(collision)
			debug_top_down_angle = collision.get_angle(-velocity.normalized())
			if wall_min_slide_angle != 0 && collision.get_angle(-velocity.normalized()) < wall_min_slide_angle + FLOOR_ANGLE_THRESHOLD:
				motion = Vector3.ZERO
			elif first_slide:
				var slide: Vector3 = collision.remainder.slide(collision.normal).normalized()
				motion = slide * (motion.length() - collision.travel.length())
			else:
				motion = collision.remainder.slide(collision.normal)
			
			if motion.dot(velocity) <= 0.0:
					motion = Vector3.ZERO

		else:
			debug_top_down_angle = 0
		first_slide = false
		if  not collision or motion.is_equal_approx(Vector3()):
			break
	
func _move_and_slide_grounded(current_platform_velocity):
	
	var motion = velocity * get_physics_process_delta_time()
	var motion_slided_up = motion.slide(up_direction)
	
	var prev_floor_normal = floor_normal
	var prev_platform_rid: = platform_rid
	var prev_platform_layer = platform_layer
	
	platform_rid = RID()
	floor_normal = Vector3.ZERO
	platform_velocity = Vector3.ZERO
	
	var vel_dir_facing_up := velocity.dot(up_direction) > 0
	# No sliding on first attempt to keep floor motion stable when possible.
	var sliding_enabled := not floor_stop_on_slope or up_direction == Vector3.ZERO
	var can_apply_constant_speed := sliding_enabled
	var first_slide := true
	var last_travel := Vector3.ZERO
	debug_last_motion = Vector3.ZERO
	for _i in range(max_slides):
		var previous_pos = position

		var collision = custom_move_and_collide(motion, false, not sliding_enabled)
		
		if collision:
			_set_collision_direction(collision)
			
			if on_floor and floor_stop_on_slope and (velocity.normalized() + up_direction).length() < 0.1:
				#if collision.travel.length() > get_safe_margin():
				#	position = position - collision.travel.slide(up_direction)
				#else:
				#	position = position - collision.travel
				if collision.travel.length() < get_safe_margin():
					position = position - collision.travel
				velocity = Vector3.ZERO
				motion = Vector3.ZERO
				break
			if collision.remainder.is_equal_approx(Vector3.ZERO):
				motion = Vector3.ZERO
				debug_last_motion = collision.travel.normalized()
				break
				
			# Apply regular sliding by default.
			var apply_default_sliding := true
			
			# move on floor only checks
			if on_wall and motion_slided_up.dot(collision.normal) <= 0:
				
				if floor_block_on_wall:
					
					# Needs horizontal motion from current motion instead of motion_slide_up
					# to properly test the angle and avoid standing on slopes
					var horizontal_motion = motion.slide(up_direction)
					var horizontal_normal = collision.normal.slide(up_direction).normalized()
					var motion_angle = abs(acos(-horizontal_normal.dot(horizontal_motion.normalized())))
					#print(str(rad2deg(motion_angle)) + " " + str(util_on_floor_only()) + " " + str(motion_angle < (0.5 * PI)))
					
					if was_on_floor and transform.basis.z.dot(collision.normal) > 0.5:
						motion = motion.slide(up_direction)
						#apply_default_sliding = false
					if was_on_floor and not on_floor:
						position = position - collision.travel
					
					# Avoid to move forward on a wall if floor_block_on_wall is true.
					if not on_floor and motion_angle < 0.5 * PI:
						
						#position = position - collision.travel	
						if was_on_floor and not on_floor and not vel_dir_facing_up:

							var has_floor := custom_move_and_collide(up_direction * -Global.GRAVITY, true, true)
							# if no collision, or
							if has_floor and has_floor.travel.dot(up_direction) > -0.02: 
								on_floor = true
								platform_rid = prev_platform_rid
								platform_layer = prev_platform_layer
								platform_velocity = current_platform_velocity
								floor_normal = prev_floor_normal

						var forward = collision.normal.slide(up_direction).normalized()
						motion = motion.slide(forward)
						if velocity.dot(forward) < 0:
							velocity = velocity.slide(forward.abs())
						# Avoid being stopped during a fall
						if motion.dot(collision.normal) >= 0:
							apply_default_sliding = false
				
				# Stop horizontal motion when under wall slide threshold.
				if !motion.is_equal_approx(Vector3.ZERO) and first_slide && (wall_min_slide_angle > 0.0) && !collision.normal.is_equal_approx(up_direction):
					var horizontal_normal: Vector3 = collision.normal.slide(up_direction).normalized()
					var motion_angle = abs(acos(-horizontal_normal.dot(motion_slided_up.normalized())))	
					if motion_angle < wall_min_slide_angle:
						motion = up_direction * motion.dot(up_direction)
						velocity = up_direction * velocity.dot(up_direction)
						apply_default_sliding = false
					
				
			# constant Speed when the slope is upward
			elif floor_constant_speed and util_on_floor_only() and can_apply_constant_speed and was_on_floor and motion.dot(collision.normal) < 0:
				can_apply_constant_speed = false
				var slide: Vector3 = collision.remainder.slide(collision.normal).normalized()
				if not slide.is_equal_approx(Vector3.ZERO):
					motion = slide * (motion_slided_up.length() - collision.travel.slide(up_direction).length() - last_travel.slide(up_direction).length())
					apply_default_sliding = false;
			
			if apply_default_sliding: 
				if (sliding_enabled or not on_floor) and (not on_ceiling or slide_on_ceiling or not vel_dir_facing_up):
					var slide_motion = collision.remainder.slide(collision.normal)
					if slide_motion.dot(velocity) > 0.0:
						motion = slide_motion
					else:
						motion = Vector3.ZERO
					if slide_on_ceiling and on_ceiling:
						if vel_dir_facing_up:
							velocity = velocity.slide(collision.normal)
						else: # remove x when fall to avoid acceleration
							velocity = up_direction * up_direction.dot(velocity)
				else:
					motion = collision.remainder
					if on_ceiling and not slide_on_ceiling and vel_dir_facing_up:
						velocity = velocity.slide(up_direction)
						motion = motion.slide(up_direction)
				last_travel = collision.travel
		elif floor_constant_speed and first_slide and _on_floor_if_snapped():
			can_apply_constant_speed = false
			sliding_enabled = true # avoid to apply two time constant speed
			position = previous_pos
			var slide: Vector3 = motion.slide(prev_floor_normal).normalized()
			if not slide.is_equal_approx(Vector3.ZERO):
				motion = slide * (motion_slided_up.length())  # alternative use original_motion.length() to also take account of the y value
				collision = true
		can_apply_constant_speed = not can_apply_constant_speed and not sliding_enabled
		sliding_enabled = true
		first_slide = false

		# debug
		if not motion.is_equal_approx(Vector3.ZERO): debug_last_motion = motion.normalized()

		if not collision or motion.is_equal_approx(Vector3.ZERO):
			break

	floor_snap()
	if on_floor and not vel_dir_facing_up:
		velocity = velocity.slide(up_direction)

func _set_collision_direction(collision):
	debug_last_collision = collision
	debug_last_normal = collision.normal # for debug
	var is_top_down = up_direction == Vector3.ZERO
	if not is_top_down and acos(collision.normal.dot(up_direction)) <= floor_max_angle + FLOOR_ANGLE_THRESHOLD:
		on_floor = true
		floor_normal = collision.normal
		platform_velocity = collision.collider_velocity
		if collision.collider.has_method("get_collision_layer"): # need a way to retrieve collision layer for tilemap
			platform_layer = collision.collider.get_collision_layer()
		platform_rid = collision.get_collider_rid()

	elif not is_top_down and acos(collision.normal.dot(-up_direction)) <= floor_max_angle + FLOOR_ANGLE_THRESHOLD:
		on_ceiling = true
	else:
		platform_velocity = collision.collider_velocity
		if collision.collider.has_method("get_collision_layer"): # need a way to retrieve collision layer for tilemap
			platform_layer = collision.collider.get_collision_layer()
		platform_rid = collision.get_collider_rid()
		on_wall = true

func _on_floor_if_snapped():
	if up_direction == Vector3.ZERO or is_equal_approx(floor_snap_length, 0) or on_floor or not was_on_floor or velocity.dot(up_direction) > 0: return false
	var collision := custom_move_and_collide(up_direction * -floor_snap_length, true)
	if collision:
		if acos(collision.normal.dot(up_direction)) <= floor_max_angle + FLOOR_ANGLE_THRESHOLD:
			return true

	return false

func floor_snap():
	if up_direction == Vector3.ZERO or is_equal_approx(floor_snap_length, 0) or on_floor or not was_on_floor or velocity.dot(up_direction) > 0: return

	var collision := custom_move_and_collide(up_direction * -floor_snap_length, true)
	if collision:
		var collision_angle = acos(collision.normal.dot(up_direction))
		if collision_angle <= floor_max_angle + FLOOR_ANGLE_THRESHOLD:
			on_floor = true
			floor_normal = collision.normal
			platform_velocity = collision.collider_velocity
			if collision.collider.has_method("get_collision_layer"): # need a way to retrieve collision layer for tilemap
				platform_layer = collision.collider.get_collision_layer()
			platform_rid = collision.get_collider_rid()
			var travelled = collision.travel

			if floor_stop_on_slope:
				# move and collide may stray the object a bit because of pre un-stucking,
				# so only ensure that motion happens on floor direction in this case.
				if travelled.length() > get_safe_margin() :
					travelled = up_direction * up_direction.dot(travelled)
				else:
					travelled = Vector3.ZERO

			position = position + travelled

func _debug_col_type(i, slide = -1):
	var col = get_last_slide_collision() if slide < 0 else get_slide_collision(slide)
	if cos(col.get_normal(i).dot(up_direction)) <= floor_max_angle + FLOOR_ANGLE_THRESHOLD:
		return "floor"
	if cos(col.get_normal(i).dot(-up_direction)) <= floor_max_angle:
		return "ceiling"
	return "wall"
		
func util_on_floor():
	if Global.USE_NATIVE_METHOD: return is_on_floor()
	return on_floor

func util_on_wall():
	if Global.USE_NATIVE_METHOD: return is_on_wall()
	return on_wall

func util_on_floor_only():
	if Global.USE_NATIVE_METHOD: return is_on_floor_only()
	return on_floor and not on_wall and not on_ceiling

func util_on_wall_only():
	if Global.USE_NATIVE_METHOD: return is_on_wall_only()
	return on_wall and not on_floor and not on_ceiling

func util_latest_collision():
	if Global.USE_NATIVE_METHOD:
		return get_last_slide_collision()
	else:
		return debug_last_collision

func util_last_motion():
	if Global.USE_NATIVE_METHOD:
		return get_last_motion()
	else:
		return debug_last_motion
