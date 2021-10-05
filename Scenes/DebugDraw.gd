extends Control

@onready var player = owner.get_node("Player")
var width = 2
var lenght = 1

func _process(_delta):
	update()

func _draw():
	if Global.DRAW_DEBUG_LINE: 
		var origin = player.global_transform.origin + Vector3(0, -0.8, 0)
		var camera = player.camera
		var start = camera.unproject_position(origin)
		
		# Velocity
		var vel_end = camera.unproject_position(origin + player.motion_velocity.normalized() * lenght)
		draw_debug_line(start, vel_end,  Color(0, 1, 0))
		
		# Motion
		if player.util_last_motion():
			var motion_end = camera.unproject_position(origin + player.util_last_motion().normalized() * lenght)
			draw_debug_line(start, motion_end,  Color(0, 0, 1))
			
		# Collisions
		var last_col = player.util_latest_collision() if Global.CURRENT_DEBUG_SLIDE == -1 else player.get_slide_collision(Global.CURRENT_DEBUG_SLIDE)
		if last_col:
			# Main collision
			var col_end = camera.unproject_position(origin + last_col.get_normal() * lenght)
			draw_debug_line(start, col_end,  Color(1, 0, 0))
			
			for i in last_col.get_collision_count():
				if i > 0:
					var motion_end = camera.unproject_position(origin + last_col.get_normal(i) * lenght)
					draw_debug_line(start, motion_end,  Color(1, 0.584, 0.039))
			for i in last_col.get_collision_count():
				var point = camera.unproject_position(last_col.get_position(i))
				draw_circle(point, 4, Color(1, 0.039, 0.882))

func draw_debug_line(start, end, color):
	draw_line(start, end, color, width)
	draw_triangle(end, start.direction_to(end), width*2, color)

func draw_triangle(pos, dir, size, color):
	var a = pos + dir * size
	var b = pos + dir.rotated(2*PI/3) * size
	var c = pos + dir.rotated(4*PI/3) * size
	var points = [a, b, c]
	draw_polygon(points, [color])
