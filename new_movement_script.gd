extends CharacterBody3D

@export var speed: float = 5.0
@export var gravity: float = -9.8
@export var stop_distance: float = 0.1
@export var camera: Camera3D  # Assign your Camera3D node here

var path: Array = []
var target_position: Vector3 = Vector3.ZERO

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var click_pos = get_click_position(event.position)
			if click_pos != Vector3.ZERO:
				move_to_position(click_pos)

# Converts mouse click to world position
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
	return Vector3.ZERO  # safe fallback

func _physics_process(delta):
	if path.size() > 0:
		var next_point = path[0]

		# Horizontal movement only
		var dir = next_point - global_position
		dir.y = 0
		if dir.length() > 0:
			dir = dir.normalized()
		else:
			dir = Vector3.ZERO

		# Horizontal velocity
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed

		# Gravity
		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			velocity.y = 0

		# Move with collisions
		move_and_slide()

		# Remove reached point
		if global_position.distance_to(next_point) < stop_distance:
			path.remove_at(0)
	else:
		# No path, stop horizontal movement
		velocity.x = 0
		velocity.z = 0
		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			velocity.y = 0
		move_and_slide()

# Call this to move the player
func move_to_position(pos: Vector3):
	target_position = pos
	path = [target_position]  # simple straight-line path
