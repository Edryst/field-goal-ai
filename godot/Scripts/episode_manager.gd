extends Node

# ============================================================
# EPISODE PHASES
# ============================================================

# APPROACH: Garry is attempting to kick the football.
# BALL_IN_FLIGHT: The ball has been contacted and we're
# waiting to determine the outcome of the kick.
enum EpisodePhase {
	APPROACH,
	BALL_IN_FLIGHT
}

# Tracks which phase the current episode is in.
var current_phase: EpisodePhase = EpisodePhase.APPROACH

# Maximum time allowed after contact for the ball to finish its flight.
const BALL_FLIGHT_DURATION := 6.0

# Tracks time since the kick was detected.
var ball_flight_time := 0.0

# ============================================================
# REFERENCES
# ============================================================

# Reference to Garry so the episode manager can tell him
# when to reset between attempts.
@onready var garry = $"../Garry"

# Reference to the football so we can reset it between attempts
@onready var football = $"../Football"

# Reference to the goal detector so EpisodeManager
# can respond when the football scores.
@onready var goal_detector: Area3D = $"../GoalPost/GoalDetector"

# ============================================================
# EPISODE SETTINGS
# ==========================================================

# Maximum amount of time one training attempt can run.
# For now this is deliberately short so we can quickly test
# repeated automatic resets.
const EPISODE_DURATION := 5.0

# Torso height below which Garry is considered potentially fallen.
# We will tune this value after seeing Garry's actual heights.
const FALL_HEIGHT := 0.75

# Garry must remain below FALL_HEIGHT for this long before the episode has ended.
# This prevents a brief crouch or physics wobble from counting as a fall.
const FALL_GRACE_TIME := 0.25

# ===========================================================
# EPISODE STATE
# ===========================================================

# How long the current episode has been running.
var episode_time := 0.0

# Counts how many training attempts have started.
var episode_number := 0

# Prevents the manager from trying to end an episode twice
# while Garry is still being reset.
var episode_ending := false

# Tracks how long Garry's torso has continuously remained
# below the fall-height threshold.
var fall_time := 0.0

func _ready() -> void:
	# Start the first training attempt as soon as the scene begins.
	start_episode()
	
	# Listen for contact between Garry's right foot and the football.
	garry.football_contact.connect(_on_football_contact)
	
	# Listen for successful field goals.
	# GoalDetector handles detection; EpisodeManager handles the outcome.
	goal_detector.goal_scored.connect(_on_goal_scored)
	
func _physics_process(delta: float) -> void:
	# Don't process episode conditions during a reset.
	if episode_ending:
		return

	match current_phase:
		EpisodePhase.APPROACH:
			# Count time available for Garry to kick.
			episode_time += delta

			# Check whether Garry has fallen.
			if garry.get_torso_height() < FALL_HEIGHT:
				fall_time += delta
			else:
				fall_time = 0.0

			# End early if Garry stays below the fall threshold.
			if fall_time >= FALL_GRACE_TIME:
				end_episode("fell")
				return

			# End if Garry never contacts the ball.
			if episode_time >= EPISODE_DURATION:
				end_episode("timeout")
				return

		EpisodePhase.BALL_IN_FLIGHT:
			# Garry's balance no longer affects episode termination.
			# Give the football time to reach the goal.
			ball_flight_time += delta

			# Temporary flight timeout until we implement
			# goal detection and other ball outcomes.
			if ball_flight_time >= BALL_FLIGHT_DURATION:
				end_episode("flight_timeout")
				return
		
func start_episode() -> void:
	
	# Prepare the next attempt.
	current_phase = EpisodePhase.APPROACH
	ball_flight_time = 0.0
	
	# Reset all timers for the new attempt.
	episode_time = 0.0
	fall_time = 0.0

	# Increase the total number of attempts.
	episode_number += 1

	print("Episode ", episode_number, " started")

func end_episode(reason: String) -> void:
	# Prevent another end condition from firing while
	# this episode is already being cleaned up.
	episode_ending = true

	# Record why this attempt ended
	print("Episode ", episode_number, " ended: ", reason)

	# Wait until Garry and Football has completely reset before allowing
	# the next training attempt to begin.
	await garry.reset_garry()
	await football.reset_football()

	# Both objects cleaned and ready for next attempt
	start_episode()
	
	# Begin next attempt
	episode_ending = false

func _on_football_contact() -> void:
	# Ignore contact during resets or after the first detected kick.
	if episode_ending or current_phase != EpisodePhase.APPROACH:
		return

	# The football has been contacted by Garry's kicking foot.
	# Switch to the flight phase so falling no longer ends the episode.
	current_phase = EpisodePhase.BALL_IN_FLIGHT
	ball_flight_time = 0.0

	print("Football contacted! Waiting for kick outcome.")

func _on_goal_scored() -> void:
	# Ignore goal events during resets or before a kick.
	# A goal should only count after Garry's right foot
	# has contacted the football.
	if episode_ending or current_phase != EpisodePhase.BALL_IN_FLIGHT:
		return

	# A successful kick ends the episode immediately.
	print("FIELD GOAL SUCCESSFUL!")

	end_episode("goal")
