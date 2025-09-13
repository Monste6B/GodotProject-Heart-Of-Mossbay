extends Camera3D

@export var player: NodePath
@export var distance: float = 6.0
@export var min_distance: float = 2.0
@export var max_distance: float = 12.0
@export var height: float = 2.0
@export var rotation_speed: float = 0.3
@export var zoom_speed: float = 2.0
@export var rotation_smooth: float = 0.1
@export var zoom_smooth: float = 0.1
@export var collision_margin: float = 0.5

var player_ref: Node3D
var yaw: float = 0.0
var pitch: float = 20.0
var current_distance: float

# Camera’s default local position on the spring arm
var camera_local_offset: Vector3 = Vector3(0,0,0)

func _ready():
	if player != null:
		player_ref = get_node(player)
	else:
		push_error("Player node not assigned!")

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	current_distance = distance

	# Cache camera local offset (child of SpringArm3D)
	camera_local_offset = global_transform.origin - player_ref.global_position

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		yaw -= event.relative.x * rotation_speed
		pitch = clamp(pitch - event.relative.y * rotation_speed, -20, 60)

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

	# Smooth rotation
	yaw = lerp_angle(yaw, yaw, rotation_smooth)
	pitch = lerp_angle(pitch, pitch, rotation_smooth)

	# Calculate camera position relative to player
	var rotation_basis = Basis(Vector3.UP, deg_to_rad(yaw))
	rotation_basis = rotation_basis.rotated(rotation_basis.x, deg_to_rad(pitch))
	var offset = -rotation_basis.z * current_distance
	global_position = target_pos + offset

	# Prevent camera from clipping into ground
	var ground_check_from = global_position + Vector3.UP * 1.0
	var ground_check_to = global_position - Vector3.UP * 5.0
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ground_check_from, ground_check_to)
	var result = space_state.intersect_ray(query)
	if result:
		if global_position.y < result.position.y + collision_margin:
			global_position.y = result.position.y + collision_margin

	# Always look at player
	look_at(target_pos, Vector3.UP)
