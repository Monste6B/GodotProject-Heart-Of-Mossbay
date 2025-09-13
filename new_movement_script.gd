extends CharacterBody3D

@export var player_speed = 5.0
@export var view_distance = 10

var player
var camera
var world_grid = []  # Your full level grid (0=walkable, 1=blocked)
var local_grid = []
var path = []
var player_target = null

func _ready():
	player = $Player
	camera = $Camera
	# Example world grid, replace with your own
	world_grid = [
		[0,0,0,0,0],
		[0,1,1,1,0],
		[0,0,0,0,0],
		[0,1,0,1,0],
		[0,0,0,0,0]
	]

func _input(event):
	if event.is_action_pressed("click"):
		var mouse_pos = event.position
		var target_pos = get_click_position(mouse_pos)
		if target_pos != null:
			generate_local_grid()
			player_target = get_safe_target(target_pos)
			path = calculate_path(player.global_position, player_target)

# Convert mouse click to world position
func get_click_position(mouse_pos):
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	var space_state = get_world_3d().direct_space_state

	# FIXED for Godot 4: use PhysicsRayQueryParameters3D
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)

	if result:
		return result.position
	return null

# Generate a sub-grid around the player based on view distance
func generate_local_grid():
	var player_cell = world_to_grid(player.global_position)
	local_grid.clear()
	for z_offset in range(-view_distance, view_distance+1):
		var row = []
		for x_offset in range(-view_distance, view_distance+1):
			var x = player_cell.x + x_offset
			var z = player_cell.y + z_offset
			if x >= 0 and x < world_grid[0].size() and z >= 0 and z < world_grid.size():
				row.append(world_grid[z][x])
			else:
				row.append(1) # treat out-of-bounds as blocked
		local_grid.append(row)

# Find a safe target if clicked cell is blocked
func get_safe_target(target_pos):
	var target_cell = world_to_grid(target_pos)
	if local_grid[target_cell.y][target_cell.x] == 0:
		return target_pos
	else:
		# Naive: move to nearest empty neighbor (can improve with A*)
		for dz in range(-1,2):
			for dx in range(-1,2):
				var nx = target_cell.x + dx
				var nz = target_cell.y + dz
				if nx >= 0 and nx < local_grid[0].size() and nz >= 0 and nz < local_grid.size():
					if local_grid[nz][nx] == 0:
						return grid_to_world(nx, nz)
		return player.global_position

# Convert world position to grid coordinates
func world_to_grid(pos: Vector3) -> Vector2:
	return Vector2(floor(pos.x), floor(pos.z))

# Convert grid coordinates back to world position
func grid_to_world(x: int, z: int) -> Vector3:
	return Vector3(x + 0.5, 0, z + 0.5)

# Simple A* placeholder (replace with Godot's AStar3D or your own)
func calculate_path(start_pos: Vector3, end_pos: Vector3) -> Array:
	# For now: straight line
	return [end_pos]

func _physics_process(delta):
	if path.size() > 0:
		var next_point = path[0]
		var dir = (next_point - player.global_position).normalized()
		player.global_position += dir * player_speed * delta
		if player.global_position.distance_to(next_point) < 0.1:
			path.remove(0)
