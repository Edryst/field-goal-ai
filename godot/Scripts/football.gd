extends RigidBody3D

func _ready() -> void:
	# Apply instantanious shove (impulse)
	apply_central_impulse(
		Vector3(
		0.0, # x: no sideways force
		1.95, # y: upwards
		-8.0) # z: the direction towards goal (along negative z) 
		)
		
	# Rotation of the football
	angular_velocity = Vector3(12.0, 0.0, 0.0)
