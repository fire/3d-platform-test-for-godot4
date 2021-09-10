extends Node
@onready var player = owner.get_node("Player")

var paused = false
var step_once = false

func _ready():
	_update_label(false)

func _change_current_slide(index):
	if index >= 0 and index < player.get_slide_collision_count():
		Global.CURRENT_DEBUG_SLIDE = index
		
func _input(_event):
	if paused:
		if Input.is_action_just_pressed("slide_1"):
			_change_current_slide(0)
		if Input.is_action_just_pressed("slide_2"):
			_change_current_slide(1)
		if Input.is_action_just_pressed("slide_3"):
			_change_current_slide(2)
		if Input.is_action_just_pressed("slide_4"):
			_change_current_slide(3)
		if Input.is_action_just_pressed("previous_slide"):
			if Global.CURRENT_DEBUG_SLIDE == -1:
				_change_current_slide(player.get_slide_collision_count() -2)
			else:
				_change_current_slide(Global.CURRENT_DEBUG_SLIDE - 1)
		if Input.is_action_just_pressed("next_slide"):
			if Global.CURRENT_DEBUG_SLIDE != -1:
				_change_current_slide(Global.CURRENT_DEBUG_SLIDE + 1)

func _physics_process(_delta):
	if Input.is_action_just_pressed('pause'):
		paused = !paused
		get_tree().paused = paused
		step_once = false
		if paused:
			_update_label(true)
		else:
			_update_label(false)
	
	if paused:
		if step_once:
			get_tree().paused = true
			step_once = false
		elif Input.is_action_just_pressed('step'):
			Global.CURRENT_DEBUG_SLIDE = -1
			get_tree().paused = false
			step_once = true

func _update_label(display:bool):
	owner.find_node("Pause").visible = display
	owner.find_node("PauseCommand").visible = display
