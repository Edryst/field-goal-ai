extends Node

# Reference to Garry so the episode manager can tell him
# when to reset between attempts.
@onready var garry = $"../Garry"

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
	
func _physics_process(delta: float) -> void:
	# Do not evaluate the episode while it is already ending
	# and Garry is being reset.
	if episode_ending:
		return

	# Track the total duration of the current attempt.
	episode_time += delta

	# ------------------------------------------------------------
	# FALL DETECTION
	# ------------------------------------------------------------

	# Check whether Garry's torso has dropped below our
	# minimum acceptable height.
	if garry.get_torso_height() < FALL_HEIGHT:
		# Keep track of how long he has remained too low.
		fall_time += delta
	else:
		# If Garry gets back above the threshold, he has recovered,
		# so discard the accumulated fall time.
		fall_time = 0.0

	# Only declare a fall if Garry has remained too low
	# continuously for the required grace period.
	if fall_time >= FALL_GRACE_TIME:
		end_episode("fell")
		return

	# ------------------------------------------------------------
	# TIME LIMIT
	# ------------------------------------------------------------

	# If Garry has not already fallen, end the attempt when
	# the maximum episode duration is reached.
	if episode_time >= EPISODE_DURATION:
		end_episode("timeout")
		return
		
func start_episode() -> void:
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

	print(
		"Episode ",
		episode_number,
		" ended: ",
		reason
	)

	# Wait until Garry has completely reset before allowing
	# the next training attempt to begin.
	await garry.reset_garry()

	start_episode()

	episode_ending = false
