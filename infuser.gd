extends Node3D

func _process(_delta: float) -> void:
	
	if Input.is_action_just_pressed("ui_accept"):
		$AudioStreamPlayer3D.play()
