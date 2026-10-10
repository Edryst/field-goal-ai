extends RigidBody3D


# ============================================================
# FOOTBALL RESET DATA
# ============================================================

# Stores the football's original position and rotation.
var initial_transform: Transform3D


func _ready() -> void:
	# Remember where the football starts before physics moves it.
	initial_transform = global_transform


func reset_football() -> void:
	# Temporarily prevent gravity and collisions from moving the ball.
	freeze = true

	# Return the football to its original position and rotation.
	global_transform = initial_transform

	# Remove all movement from the previous attempt.
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	# Allow one physics frame for the reset position to register.
	await get_tree().physics_frame

	# Clear any remaining movement before releasing the football.
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	# Resume normal physics simulation.
	freeze = false
	sleeping = false
