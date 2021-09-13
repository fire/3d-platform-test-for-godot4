extends Node3D

func _ready():
	$Texts/VBox/GDScriptButton.pressed = !Global.USE_NATIVE_METHOD
	$Texts/VBox/SnapButton.pressed = Global.APPLY_SNAP
	$Texts/VBox/ConstantSpeedButton.pressed = Global.FLOOR_CONSTANT_SPEED
	$Texts/VBox/OnFloorButton.pressed = Global.FLOOR_BLOCK_ON_WALL
	$Texts/VBox/AirFrictionButton.pressed = Global.APPLY_AIR_FRICTION
	$Texts/VBox/AccelerationButton.pressed = Global.APPLY_ACCELERATION
	$Texts/VBox/MaxFloorAngle/MaxFloorAngleSlider.value = rad2deg(Global.FLOOR_MAX_ANGLE)
	$Texts/VBox/WallMinAngle/WallMinAngleSlideSlider.value = rad2deg(Global.WALL_MIN_SLIDE_ANGLE)

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
	$Texts/VBox/MaxFloorAngle/MaxFloorAngleLabel.text = "Floor max angle: %.0f°" % round(value) 
	Global.FLOOR_MAX_ANGLE = deg2rad(value)

func _on_WallMinAngleSlideSlider_value_changed(value):
	$Texts/VBox/WallMinAngle/WallMinAngleSlideLabel.text = "Min slide angle: %.0f°" % round(value)
	Global.WALL_MIN_SLIDE_ANGLE = deg2rad(value)

func _on_StopSlopeButton_toggled(button_pressed):
	Global.FLOOR_STOP_ON_SLOPE = button_pressed

func _on_DrawLines_toggled(button_pressed):
	Global.DRAW_DEBUG_LINE = button_pressed

func _on_DrawHUD_toggled(button_pressed):
	Global.DRAW_HUD = button_pressed
