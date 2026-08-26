extends Node

@onready var left_hip: HingeJoint3D = $LeftLeg/LeftHipJoint
@onready var left_knee: HingeJoint3D = $LeftLeg/LeftKneeJoint
@onready var left_ankle: HingeJoint3D = $LeftLeg/LeftAnkleJoint

@onready var right_hip: HingeJoint3D = $RightLeg/RightHipJoint
@onready var right_knee: HingeJoint3D = $RightLeg/RightKneeJoint
@onready var right_ankle: HingeJoint3D = $RightLeg/RightAnkleJoint

const MAX_JOINT_SPEED := 180.0
const MOTOR_IMPULSE := 5.0

func _ready() -> void:
	print("Garry controller online")
	
	apply_actions([
		0.0,
		-0.5,
		0.6,
		-0.2,
		0.0,
		1.0
	
	])

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
	
func apply_actions(actions: Array[float]) -> void:
	
	if actions.size() != 6:
		push_error("Garry expected 6 actions, got %d" % actions.size())
	
	set_joint_action(left_hip, actions[0])
	set_joint_action(left_knee, actions[1])
	set_joint_action(left_ankle, actions[2])
	set_joint_action(right_hip, actions[3])
	set_joint_action(right_knee, actions[4])
	set_joint_action(right_ankle, actions[5])
