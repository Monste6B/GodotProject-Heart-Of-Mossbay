# Player.gd
extends CharacterBody3D

@export var speed: float = 5.0
@export var gravity: float = -9.8
@export var stop_distance: float = 0.1
@export var camera: Camera3D  # Drag Camera node from SpringArm here

var target_position: Vector3 = Vector3.ZERO
var moving: bool = false

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if camera == null:
				push_error("Camera not assigned!")
				return

			var from = camera.project_ray_origin(event.position)
			var to = from + camera.project_ray_normal(event.position) * 1000

			var query = PhysicsRayQueryParameters3D.create(from, to)
			var result = get_world_3d().direct_space_state.intersect_ray(query)
			if result and result.position != null:
				target_position = result.position
				moving = true

func _physics_process(delta):
	if moving:
		var dir = target_position - global_position
		dir.y = 0  # horizontal only

		if dir.length() < stop_distance:
			moving = false
			velocity.x = 0
			velocity.z = 0
		else:
			dir = dir.normalized()
			velocity.x = dir.x * speed
			velocity.z = dir.z * speed

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	move_and_slide()
