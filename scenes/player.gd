extends CharacterBody3D

@export var speed: float = 5.0
@export var gravity: float = -9.8
@export var stop_distance: float = 0.2
@export var camera: Camera3D

# Hook up your AnimationPlayer node here
@onready var anim_player: AnimationPlayer = $AnimationPlayer

var path: Array = []
var target_position: Vector3 = Vector3.ZERO
var is_attacking: bool = false

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# If shift is held, treat it as attack input instead of move
		if Input.is_key_pressed(KEY_SHIFT):
			trigger_attack()
		else:
			var click_pos = get_click_position(event.position)
			if click_pos != Vector3.ZERO:
				move_to_position(click_pos)

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
	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# Handle movement
	if path.size() > 0 and not is_attacking:
		var next_point = path[0]
		var dir = next_point - global_position
		var distance = dir.length()

		if distance > 0:
			dir = dir.normalized()

			# Rotate player (horizontal only)
			var look_dir = dir
			look_dir.y = 0
			if look_dir.length() > 0:
				look_at(global_position + look_dir, Vector3.UP)
				rotate_y(deg_to_rad(180))  # adjust facing if needed

			# Horizontal velocity
			velocity.x = dir.x * speed
			velocity.z = dir.z * speed
		else:
			velocity.x = 0
			velocity.z = 0

		move_and_slide()

		# Stop if close to target
		if distance < stop_distance:
			path.remove_at(0)
			velocity.x = 0
			velocity.z = 0
	else:
		velocity.x = 0
		velocity.z = 0
		move_and_slide()

	# Update animation each frame
	update_animation()

func move_to_position(pos: Vector3):
	target_position = pos
	path = [target_position]

# ----------------------
# Animation + Attack
# ----------------------

func update_animation():
	if is_attacking:
		play_animation("Slice")  # change if your attack anim has a different name
	elif path.size() > 0:
		play_animation("Run")    # match exactly what’s in AnimationPlayer
	else:
		play_animation("Idle")

func trigger_attack():
	if not is_attacking:
		is_attacking = true
		play_animation("Slice")
		# When the animation finishes, reset attack state
		# (connect the "animation_finished" signal in the editor to _on_animation_finished)

func _on_animation_finished(anim_name: String):
	if anim_name == "Slice":
		is_attacking = false

func play_animation(anim_name: String):
	if anim_player and anim_player.has_animation(anim_name):
		if anim_player.current_animation != anim_name:
			anim_player.play(anim_name)
	else:
		push_warning("Animation not found: %s" % anim_name)
