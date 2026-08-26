extends Node

@onready var torso: RigidBody3D = $Torso

# Left Leg Segments
@onready var left_thigh: RigidBody3D = $LeftLeg/LeftThigh
@onready var left_shin: RigidBody3D = $LeftLeg/LeftShin
@onready var left_foot: RigidBody3D = $LeftLeg/LeftFoot

# Left Leg Joints
@onready var left_hip: HingeJoint3D = $LeftLeg/LeftHipJoint
@onready var left_knee: HingeJoint3D = $LeftLeg/LeftKneeJoint
@onready var left_ankle: HingeJoint3D = $LeftLeg/LeftAnkleJoint

# Right Leg Segments
@onready var right_thigh: RigidBody3D = $RightLeg/RightThigh
@onready var right_shin: RigidBody3D = $RightLeg/RightShin
@onready var right_foot: RigidBody3D = $RightLeg/RightFoot

# Right Leg Joints
@onready var right_hip: HingeJoint3D = $RightLeg/RightHipJoint
@onready var right_knee: HingeJoint3D = $RightLeg/RightKneeJoint
@onready var right_ankle: HingeJoint3D = $RightLeg/RightAnkleJoint

const MAX_JOINT_SPEED := 180.0
const MOTOR_IMPULSE := 5.0

func _ready() -> void:
	print("Garry controller online")
	
	apply_actions([
		0.0,
		0.0,
		0.0,
		0.0,
		0.0,
		0.0
	
	])

func _physics_process(_delta: float) -> void:
	
	var actions: Array[float] = [
		Input.get_axis("left_hip_negative", "left_hip_positive"),
		Input.get_axis("left_knee_negative", "left_knee_positive"),
		Input.get_axis("left_ankle_negative", "left_ankle_positive"),
		Input.get_axis("right_hip_negative", "right_hip_positive"),
		Input.get_axis("right_knee_negative", "right_knee_positive"),
		Input.get_axis("right_ankle_negative", "right_ankle_positive"),
	]
	
	apply_actions(actions)
	
func apply_actions(actions: Array[float]) -> void:
	
	if actions.size() != 6:
		push_error("Garry expected 6 actions, got %d" % actions.size())
		return
		
	set_joint_action(left_hip, actions[0])
	set_joint_action(left_knee, actions[1])
	set_joint_action(left_ankle, actions[2])
	set_joint_action(right_hip, actions[3])
	set_joint_action(right_knee, actions[4])
	set_joint_action(right_ankle, actions[5])

func get_observation() -> Array[float]:
	return [
		# Torso orientation
		torso.rotation.x,
		torso.rotation.y,
		torso.rotation.z,

		# Torso angular velocity
		torso.angular_velocity.x,
		torso.angular_velocity.y,
		torso.angular_velocity.z,
		
		# Torso linear velocity
		torso.linear_velocity.x,
		torso.linear_velocity.y,
		torso.linear_velocity.z,

		# Torso height
		torso.global_position.y,

		# Left leg joint angles
		get_joint_angle(torso, left_thigh),
		get_joint_angle(left_thigh, left_shin),
		get_joint_angle(left_shin, left_foot),

		# Right leg joint angles
		get_joint_angle(torso, right_thigh),
		get_joint_angle(right_thigh, right_shin),
		get_joint_angle(right_shin, right_foot),

		# Left leg joint velocities
		get_joint_velocity(torso, left_thigh),
		get_joint_velocity(left_thigh, left_shin),
		get_joint_velocity(left_shin, left_foot),

		# Right leg joint velocities
		get_joint_velocity(torso, right_thigh),
		get_joint_velocity(right_thigh, right_shin),
		get_joint_velocity(right_shin, right_foot)
	]
	
func get_joint_angle(body_a: RigidBody3D, body_b: RigidBody3D) -> float:
	var relative_basis := body_a.global_transform.basis.inverse() * body_b.global_transform.basis
	var relative_rotation := relative_basis.get_euler()

	return relative_rotation.x
	
func get_joint_velocity(body_a: RigidBody3D, body_b: RigidBody3D) -> float:
	var relative_velocity := body_b.angular_velocity - body_a.angular_velocity
	var local_relative_velocity := body_a.global_transform.basis.inverse() * relative_velocity

	return local_relative_velocity.x

func set_joint_action(joint: HingeJoint3D, action: float) -> void:
	action = clamp(action, -1.0, 1.0)
	
	joint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
	
	joint.set_param(
		HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY,
		deg_to_rad(action * MAX_JOINT_SPEED)
	)
	
	joint.set_param(
		HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE,
		MOTOR_IMPULSE
	)
	
