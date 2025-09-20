extends CharacterBody3D

@export var speed: float = 5.0
@export var gravity: float = 9.8
@export var stop_distance: float = 0.2
@export var camera: Camera3D   # Assign your Camera3D here in the Inspector

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var anim_player: AnimationPlayer = $"AuxScene/AnimationPlayer"

func _ready():
	if agent == null:
		push_warning("⚠️ NavigationAgent3D not found under CharacterBody3D!")
		return

	if anim_player == null:
		push_warning("⚠️ AnimationPlayer not found under AuxScene!")

	# Ensure the agent finds the navmesh in the world
	if agent.get_navigation_map() == null:
		agent.navmap_wait_timer = 0.1

# Handle mouse clicks (click-to-move)
func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var target_pos = get_click_position(event.position)
		if target_pos != Vector3.ZERO:
			move_to_position(target_pos)

func get_click_position(mouse_pos: Vector2) -> Vector3:
	if camera == null:
		push_warning("⚠️ Camera not assigned!")
		return Vector3.ZERO

	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000.0
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)

	if result:
		return result.position
	return Vector3.ZERO

func move_to_position(pos: Vector3) -> void:
	if agent:
		agent.target_position = pos

func _physics_process(delta: float) -> void:
	if agent == null:
		return

	var moving := not agent.is_navigation_finished()

	if moving:
		var next_point: Vector3 = agent.get_next_path_position()
		var dir: Vector3 = next_point - global_position
		dir.y = 0

		# Stop if close enough
		if dir.length() < stop_distance:
			velocity.x = 0
			velocity.z = 0
			moving = false
		else:
			dir = dir.normalized()
			velocity.x = dir.x * speed
			velocity.z = dir.z * speed

			# Rotate only if angle difference is significant
			var facing = -transform.basis.z
			var angle_diff = facing.angle_to(dir)
			if angle_diff > 0.05: # ~3 degrees
				look_at(global_position + dir, Vector3.UP)
				rotate_y(deg_to_rad(180))
	else:
		velocity.x = 0
		velocity.z = 0

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	move_and_slide()

	# Animations
	if anim_player:
		if moving:
			if anim_player.current_animation != "RunWithSword0":
				anim_player.play("RunWithSword0")
		else:
			if anim_player.current_animation != "GreatSwordIdle0":
				anim_player.play("GreatSwordIdle0")
