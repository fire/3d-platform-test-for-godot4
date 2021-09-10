extends Node3D

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

