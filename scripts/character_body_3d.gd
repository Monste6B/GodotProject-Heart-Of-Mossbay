extends CharacterBody3D

# ──────────────── MOVEMENT SETTINGS ────────────────
@export var speed: float = 5.0
@export var gravity: float = -9.8
@export var stop_distance: float = 0.2
@export var camera: Camera3D

# ──────────────── ANIMATION SETTINGS ────────────────
@export var anim_player_path: NodePath   # Drag your AnimationPlayer here in the Inspector
@onready var anim_player: AnimationPlayer = get_node_or_null(anim_player_path)

# ──────────────── INTERNAL VARIABLES ────────────────
var path: Array = []
var target_position: Vector3 = Vector3.ZERO

# ──────────────── INPUT HANDLING ────────────────
func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var click_pos = get_click_position(event.position)
		if click_pos != Vector3.ZERO:
			move_to_position(click_pos)

# ──────────────── RAYCAST FOR CLICK-TO-MOVE ────────────────
func get_click_position(mouse_pos: Vector2) -> Vector3:
	if camera == null:
		push_error("Camera not assigned!")
		return Vector3.ZERO

	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)
	if result:
		return result.position
	return Vector3.ZERO

# ──────────────── PHYSICS (MOVEMENT + ANIMATIONS) ────────────────
func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# Movement logic
	if path.size() > 0:
		var next_point = path[0]
		var dir = next_point - global_position
		var distance = dir.length()

		if distance > 0:
			dir = dir / distance  # normalize

			# Rotate player (horizontal only)
			var look_dir = dir
			look_dir.y = 0
			if look_dir.length() > 0:
				look_at(global_position + look_dir, Vector3.UP)
				rotate_y(deg_to_rad(180))  # adjust for +Z facing

			# Horizontal velocity
			velocity.x = dir.x * speed
			velocity.z = dir.z * speed

			# Play "Run" animation
			play_animation("Run")
		else:
			velocity.x = 0
			velocity.z = 0

		move_and_slide()

		# Stop and remove point if close
		if distance < stop_distance:
			path.remove_at(0)
			velocity.x = 0
			velocity.z = 0
	else:
		velocity.x = 0
		velocity.z = 0
		move_and_slide()

		# Play "Idle" animation when standing still
		play_animation("Idle")

# ──────────────── HELPER: MOVE TO POSITION ────────────────
func move_to_position(pos: Vector3):
	target_position = pos
	path = [target_position]

# ──────────────── HELPER: PLAY ANIMATION SAFELY ────────────────
func play_animation(anim_name: String):
	if anim_player == null:
		push_warning("AnimationPlayer not assigned!")
		return

	if anim_player.has_animation(anim_name):
		if anim_player.current_animation != anim_name:
			anim_player.play(anim_name)
	else:
		push_warning("Animation not found: %s" % anim_name)
