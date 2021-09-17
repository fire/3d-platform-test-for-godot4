extends CanvasLayer

func _on_MinSlide_value_changed(value):
	$MinSlideLabel.text = "Min Slide : %.2f" % value
	Global.WALL_MIN_SLIDE_ANGLE = deg2rad(value)
