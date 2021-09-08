extends Control

@onready var player = owner
var width = 4
var lenght = 1

func _process(_delta):
	update()

func _draw():
	if Global.DRAW_DEBUG_LINE: 
		var origin = player.global_transform.origin + Vector3(0, -0.8, 0)
		var collision_normal = player.util_latest_collision()
		var camera = player.camera
		var start = camera.unproject_position(origin)
		
		# Velocity
		
		var vel_end = camera.unproject_position(origin + player.linear_velocity.normalized() * lenght)
		draw_debug_line(start, vel_end,  Color(0, 1, 0))
		
		# Collision
		if player.util_latest_collision():
			var col_end = camera.unproject_position(origin + player.util_latest_collision().normal * lenght)
			draw_debug_line(start, col_end,  Color(1, 0, 0))
		
		# Motion
		if player.util_last_motion():
			var motion_end = camera.unproject_position(origin + player.util_last_motion() * lenght)
			draw_debug_line(start, motion_end,  Color(0, 0, 1))

func draw_debug_line(start, end, color):
	draw_line(start, end, color, width)
	draw_triangle(end, start.direction_to(end), width*2, color)

func draw_triangle(pos, dir, size, color):
	var a = pos + dir * size
	var b = pos + dir.rotated(2*PI/3) * size
	var c = pos + dir.rotated(4*PI/3) * size
	var points = [a, b, c]
	draw_polygon(points, [color])
