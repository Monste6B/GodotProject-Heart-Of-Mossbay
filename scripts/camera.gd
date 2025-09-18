extends Camera3D

@export var player: NodePath
@export var height: float = 2.0
@export var distance: float = 6.0
@export var min_distance: float = 2.0
@export var max_distance: float = 12.0
@export var rotation_speed: float = 0.3
@export var zoom_speed: float = 2.0
@export var rotation_smooth: float = 0.1
@export var zoom_smooth: float = 0.1
@export var collision_margin: float = 0.3

var player_ref: Node3D
var yaw: float = 0.0
var pitch: float = 20.0
var current_distance: float

func _ready():
	if player != null:
		player_ref = get_node(player)
	else:
		push_error("Player node not assigned!")

	current_distance = distance
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _unhandled_input(event):
	# Right-click drag for rotation
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		yaw -= event.relative.x * rotation_speed
		pitch = clamp(pitch - event.relative.y * rotation_speed, -20, 60)

	# Mouse wheel zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			distance = max(min_distance, distance - zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			distance = min(max_distance, distance + zoom_speed)

func _process(_delta):
	if player_ref == null:
		return

	# Smooth zoom
	current_distance = lerp(current_distance, distance, zoom_smooth)

	# Target position above player
	var target_pos = player_ref.global_position + Vector3.UP * height

	# Calculate rotation basis
	var rotation_basis = Basis(Vector3.UP, deg_to_rad(yaw))
	rotation_basis = rotation_basis.rotated(rotation_basis.x, deg_to_rad(pitch))

	# Desired camera position
	var desired_offset = -rotation_basis.z * current_distance
	var desired_pos = target_pos + desired_offset

	# Raycast from player to desired camera position
	var space_state = get_world_3d().direct_space_state
	var ray_query = PhysicsRayQueryParameters3D.create(target_pos, desired_pos)
	ray_query.exclude = [player_ref]
	var result = space_state.intersect_ray(ray_query)

	if result:
		# Stop camera slightly in front of obstacle
		global_position = result.position + (target_pos - desired_pos).normalized() * collision_margin
	else:
		global_position = desired_pos

	# Always look at player
	look_at(target_pos, Vector3.UP)
