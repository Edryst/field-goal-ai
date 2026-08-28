extends Node


# ============================================================
# RIGID BODY REFERENCES
# ============================================================

# Main body.
@onready var torso: RigidBody3D = $Torso

# Left leg segments.
@onready var left_thigh: RigidBody3D = $LeftLeg/LeftThigh
@onready var left_shin: RigidBody3D = $LeftLeg/LeftShin
@onready var left_foot: RigidBody3D = $LeftLeg/LeftFoot

# Right leg segments.
@onready var right_thigh: RigidBody3D = $RightLeg/RightThigh
@onready var right_shin: RigidBody3D = $RightLeg/RightShin
@onready var right_foot: RigidBody3D = $RightLeg/RightFoot


# ============================================================
# JOINT REFERENCES
# ============================================================

# Left leg joints.
@onready var left_hip: HingeJoint3D = $LeftLeg/LeftHipJoint
@onready var left_knee: HingeJoint3D = $LeftLeg/LeftKneeJoint
@onready var left_ankle: HingeJoint3D = $LeftLeg/LeftAnkleJoint

# Right leg joints.
@onready var right_hip: HingeJoint3D = $RightLeg/RightHipJoint
@onready var right_knee: HingeJoint3D = $RightLeg/RightKneeJoint
@onready var right_ankle: HingeJoint3D = $RightLeg/RightAnkleJoint


# ============================================================
# MOTOR SETTINGS
# ============================================================

# Maximum joint motor speed.
# An action of 1.0 means +180 degrees per second.
# An action of -1.0 means -180 degrees per second.
const MAX_JOINT_SPEED := 180.0

# Maximum amount of force the motor can use to reach its target velocity.
const MOTOR_IMPULSE := 5.0


# ============================================================
# RESET DATA
# ============================================================

# Contains every physical body part that must be reset between attempts.
var rigid_bodies: Array[RigidBody3D] = []

# Contains every controllable joint.
var joints: Array[HingeJoint3D] = []

# Stores each rigid body's original world transform.
# This gives us the starting position and rotation for resets.
var initial_transforms: Dictionary = {}

# Prevents normal controls from running while Garry is being reset.
var is_resetting := false


func _ready() -> void:
	print("Garry controller online")

	# Store all physical body parts in one list so we can easily
	# loop through them when resetting Garry.
	rigid_bodies = [
		torso,
		left_thigh,
		left_shin,
		left_foot,
		right_thigh,
		right_shin,
		right_foot
	]

	# Store all six controllable joints in one list.
	joints = [
		left_hip,
		left_knee,
		left_ankle,
		right_hip,
		right_knee,
		right_ankle
	]

	# Record Garry's exact starting pose before physics has time
	# to make him fall over.
	for body in rigid_bodies:
		initial_transforms[body] = body.global_transform

	# Start all motors enabled but with zero requested movement.
	apply_actions([
		0.0,
		0.0,
		0.0,
		0.0,
		0.0,
		0.0
	])


func _physics_process(_delta: float) -> void:
	# Ignore player/AI controls while a reset is taking place.
	if is_resetting:
		return

	# Check reset before applying another frame of joint movement.
	if Input.is_action_just_pressed("reset_garry"):
		reset_garry()
		return

	# Each value is between -1.0 and 1.0.
	#
	# Array order:
	# 0 = left hip
	# 1 = left knee
	# 2 = left ankle
	# 3 = right hip
	# 4 = right knee
	# 5 = right ankle
	var actions: Array[float] = [
		Input.get_axis("left_hip_negative", "left_hip_positive"),
		Input.get_axis("left_knee_negative", "left_knee_positive"),
		Input.get_axis("left_ankle_negative", "left_ankle_positive"),
		Input.get_axis("right_hip_negative", "right_hip_positive"),
		Input.get_axis("right_knee_negative", "right_knee_positive"),
		Input.get_axis("right_ankle_negative", "right_ankle_positive"),
	]

	# Send the six requested movements to Garry's joints.
	apply_actions(actions)


func apply_actions(actions: Array[float]) -> void:
	# Garry currently has exactly six controllable joints,
	# so every action array must contain six values.
	if actions.size() != 6:
		push_error("Garry expected 6 actions, got %d" % actions.size())
		return

	# Each action controls the target rotational velocity
	# of one joint.
	set_joint_action(left_hip, actions[0])
	set_joint_action(left_knee, actions[1])
	set_joint_action(left_ankle, actions[2])

	set_joint_action(right_hip, actions[3])
	set_joint_action(right_knee, actions[4])
	set_joint_action(right_ankle, actions[5])


func reset_garry() -> void:
	# Prevent normal controls from running during the reset.
	is_resetting = true

	# Temporarily disable every joint motor.
	# This stops the motors from trying to move the limbs
	# while we teleport Garry back to his starting pose.
	for joint in joints:
		joint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, false)

	# Freeze every body so gravity and collisions cannot interfere
	# while we restore the original pose.
	for body in rigid_bodies:
		body.freeze = true

		# Restore original position and rotation.
		body.global_transform = initial_transforms[body]

		# Remove all previous movement.
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO

	# Allow one physics frame for the reset pose to register.
	await get_tree().physics_frame

	# Release Garry back into the physics simulation.
	for body in rigid_bodies:
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO
		body.freeze = false
		body.sleeping = false

	# Re-enable the motors with zero requested movement.
	# The AI/player can start controlling them again next frame.
	apply_actions([
		0.0,
		0.0,
		0.0,
		0.0,
		0.0,
		0.0
	])

	is_resetting = false


func get_observation() -> Array[float]:
	# This array represents Garry's current physical state.
	# Eventually Python will receive these values and use them
	# as the reinforcement-learning agent's observations.
	return [
		# --------------------------------------------------------
		# TORSO ORIENTATION
		# --------------------------------------------------------
		# Rotation around X, Y and Z in radians.
		torso.rotation.x,
		torso.rotation.y,
		torso.rotation.z,

		# --------------------------------------------------------
		# TORSO ANGULAR VELOCITY
		# --------------------------------------------------------
		# How quickly the torso is rotating around each axis.
		torso.angular_velocity.x,
		torso.angular_velocity.y,
		torso.angular_velocity.z,

		# --------------------------------------------------------
		# TORSO LINEAR VELOCITY
		# --------------------------------------------------------
		# How quickly Garry is moving through the world.
		torso.linear_velocity.x,
		torso.linear_velocity.y,
		torso.linear_velocity.z,

		# --------------------------------------------------------
		# TORSO HEIGHT
		# --------------------------------------------------------
		# Useful for determining whether Garry is upright,
		# falling, jumping or lying on the ground.
		torso.global_position.y,

		# --------------------------------------------------------
		# LEFT LEG JOINT ANGLES
		# --------------------------------------------------------
		get_joint_angle(torso, left_thigh),
		get_joint_angle(left_thigh, left_shin),
		get_joint_angle(left_shin, left_foot),

		# --------------------------------------------------------
		# RIGHT LEG JOINT ANGLES
		# --------------------------------------------------------
		get_joint_angle(torso, right_thigh),
		get_joint_angle(right_thigh, right_shin),
		get_joint_angle(right_shin, right_foot),

		# --------------------------------------------------------
		# LEFT LEG JOINT VELOCITIES
		# --------------------------------------------------------
		get_joint_velocity(torso, left_thigh),
		get_joint_velocity(left_thigh, left_shin),
		get_joint_velocity(left_shin, left_foot),

		# --------------------------------------------------------
		# RIGHT LEG JOINT VELOCITIES
		# --------------------------------------------------------
		get_joint_velocity(torso, right_thigh),
		get_joint_velocity(right_thigh, right_shin),
		get_joint_velocity(right_shin, right_foot)
	]

func get_torso_height() -> float:
	# Returns Garry's current torso height in world coordinates.
	# EpisodeManager can use this to determine whether Garry
	# has fallen without needing to know about Garry's body nodes.
	return torso.global_position.y
	
func get_joint_angle(body_a: RigidBody3D, body_b: RigidBody3D) -> float:
	# Convert body B's rotation into body A's local coordinate system.
	# This allows us to measure how much the two connected body
	# segments are rotated relative to each other.
	var relative_basis := (
		body_a.global_transform.basis.inverse()
		* body_b.global_transform.basis
	)

	var relative_rotation := relative_basis.get_euler()

	# Our hinges currently rotate around the local X axis,
	# so X is the value we use as the joint angle.
	return relative_rotation.x


func get_joint_velocity(body_a: RigidBody3D, body_b: RigidBody3D) -> float:
	# Find how quickly body B is rotating relative to body A.
	var relative_velocity := (
		body_b.angular_velocity
		- body_a.angular_velocity
	)

	# Angular velocities above are in world coordinates.
	# Convert them into body A's local coordinate system so the
	# measurement continues to make sense even when Garry rotates.
	var local_relative_velocity := (
		body_a.global_transform.basis.inverse()
		* relative_velocity
	)

	# Our hinge movement corresponds to the local X axis.
	return local_relative_velocity.x


func set_joint_action(joint: HingeJoint3D, action: float) -> void:
	# Protect against invalid AI/player values by forcing the action
	# into the allowed range of -1.0 to +1.0.
	action = clamp(action, -1.0, 1.0)

	# Make sure the joint motor is enabled.
	joint.set_flag(
		HingeJoint3D.FLAG_ENABLE_MOTOR,
		true
	)

	# Convert the normalized action into the motor's target velocity.
	#
	# Example:
	# action =  1.0 -> +180 degrees/sec
	# action =  0.5 ->  +90 degrees/sec
	# action =  0.0 ->    0 degrees/sec
	# action = -1.0 -> -180 degrees/sec
	joint.set_param(
		HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY,
		deg_to_rad(action * MAX_JOINT_SPEED)
	)

	# Set how strongly the motor is allowed to push toward
	# the requested velocity.
	joint.set_param(
		HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE,
		MOTOR_IMPULSE
	)
