extends CharacterBody3D

@export_category("Movement")
@export var speed: float = 10.0
@export var acceleration: float = 5.0

@export_category("Ball Properties")
## The visual radius of your ball mesh in meters/units.
@export var ball_radius: float = 0.5 

@export_category("Shader Targets")
@export var shader_parameter_name: String = "point_center"

@onready var ball_mesh: MeshInstance3D = $MeshInstance3D
@onready var multi_mesh_instace_hex_tiller: MultiMeshInstaceHexTiller = $"../MultiMeshInstaceHexTiller"
@onready var target_mesh = multi_mesh_instace_hex_tiller.multimesh.mesh

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta: float) -> void:
	# 1. Handle Gravity
	#if not is_on_floor():
		#velocity.y -= gravity * delta

	# 2. Get Input Direction
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# 3. Apply Movement (Acceleration and Friction)
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0, acceleration * delta)

	move_and_slide()
	
	# 4. Roll Mesh Based on Actual Movement
	_roll_ball_mesh()
	
	# 5. Update Shader Parameter
	_update_shader_position()

func _roll_ball_mesh() -> void:
	if not ball_mesh:
		return
		
	# Get the actual horizontal movement vector calculated by move_and_slide()
	var real_velocity := get_real_velocity()
	var horizontal_velocity := Vector3(real_velocity.x, 0, real_velocity.y if is_zero_approx(real_velocity.z) else real_velocity.z)
	horizontal_velocity.y = 0 # Ensure purely horizontal ground rolling
	
	var speed_length := horizontal_velocity.length()
	
	# Only calculate rotation if the ball is actually moving
	if speed_length > 0.001:
		# Direction of motion
		var move_dir := horizontal_velocity.normalized()
		
		# Rotation axis is perpendicular to movement vector on the ground plane (Vector3.UP x MoveDirection)
		var rotation_axis := Vector3.UP.cross(move_dir)
		
		# Arc length formula (s = r * theta) -> theta = distance / radius
		# Frame distance = velocity * delta
		var distance_traveled := speed_length * get_physics_process_delta_time()
		var rotation_angle := distance_traveled / ball_radius
		
		# Apply rotation in global space around the calculated axis
		ball_mesh.global_rotate(rotation_axis, rotation_angle)

func _update_shader_position() -> void:
	if target_mesh and target_mesh.surface_get_material(0):
		var material = target_mesh.surface_get_material(0) as ShaderMaterial
		if material:
			material.set_shader_parameter(shader_parameter_name, global_position)
