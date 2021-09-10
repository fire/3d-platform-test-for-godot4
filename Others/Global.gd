extends Node

var DRAW_DEBUG_LINE := true
# player
var GRAVITY := 0.98
var WALK_SPEED := 6
var RUN_SPEED := 15
var JUMP_FORCE := 20
var GROUND_ACCELERATION := 15
var AIR_ACCELERATION := 5
var FLOOR_SNAP_LENGTH := .01

var APPLY_ACCELERATION := true
var APPLY_AIR_FRICTION := true

var INFINITE_JUMP := true

var USE_NATIVE_METHOD := true

# move and slide
var APPLY_SNAP := true
var FLOOR_CONSTANT_SPEED := true
var FLOOR_STOP_ON_SLOPE := true
var FLOOR_BLOCK_ON_WALL := true
var FLOOR_MAX_ANGLE := deg2rad(45.0)
var UP_DIRECTION := Vector3.UP
var SLIDE_ON_CEILING := true
var WALL_MIN_SLIDE_ANGLE := deg2rad(0)

 # top down
var MODE_FREE := false

