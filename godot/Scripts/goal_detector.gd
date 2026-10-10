extends Area3D

# ============================================================
# GOAL DETECTION
# ============================================================

# Other nodes can listen for this signal when the football
# successfully passes through the goal detector.
signal goal_scored


func _on_body_entered(body: Node3D) -> void:
	# Ignore anything that isn't the football.
	# This prevents Garry or other physics objects
	# from accidentally triggering a goal.
	if not body.is_in_group("football"):
		return

	# The football has entered the scoring area.
	print("ITS GOOD!")

	# Tell any connected systems that a goal was scored.
	goal_scored.emit()
