extends CharacterBody3D

@export var speed: float = 5.0
@export var gravity: float = -9.8
@export var stop_distance: float = 0.1
@export var camera: Camera3D

var target_position: Vector3 = Vector3.ZERO
var moving: bool = false

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var click_pos = get_click_position(event.position)
		if click_pos != Vector3.ZERO:
			target_position = click_pos
			moving = true

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

func _physics_process(delta):
	var horizontal_velocity = Vector3.ZERO

	# Move toward target
	if moving:
		var dir = target_position - global_position
		var distance = dir.length()
		if distance < stop_distance:
			moving = false
		else:
			var horizontal_dir = Vector3(dir.x, 0, dir.z).normalized()
			horizontal_velocity = horizontal_dir * speed

	# Apply horizontal velocity
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z

	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# Move and handle collisions
	move_and_slide()
