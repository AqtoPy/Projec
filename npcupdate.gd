extends CharacterBody3D
class_name NPCController

@export var movement_speed: float = 3.0
@export var min_walk_distance: float = 5.0
@export var max_walk_distance: float = 15.0

var navigation_agent: NavigationAgent3D
var target_position: Vector3
var is_moving: bool = false
var navigation_ready: bool = false

func _ready():
    navigation_agent = $NavigationAgent3D
    
    # Ждем инициализации навигации
    NavigationServer3D.map_changed.connect(_on_navigation_map_changed)
    _check_navigation_ready()

func _on_navigation_map_changed(map_rid):
    _check_navigation_ready()

func _check_navigation_ready():
    if NavigationServer3D.map_get_iteration_id(navigation_agent.get_navigation_map()) > 0:
        navigation_ready = true
        navigation_agent.navigation_finished.connect(_on_navigation_finished)
        set_new_target()

func _physics_process(delta):
    if !navigation_ready or !is_moving:
        return
    
    var next_path_pos = navigation_agent.get_next_path_position()
    var direction = (next_path_pos - global_position).normalized()
    
    velocity = direction * movement_speed
    move_and_slide()
    
    # Плавный поворот
    if velocity.length() > 0.1:
        var target_angle = atan2(direction.x, direction.z)
        rotation.y = lerp_angle(rotation.y, target_angle, delta * 5.0)

func set_new_target():
    if !navigation_ready:
        return
    
    var random_direction = Vector3(
        randf_range(-1, 1),
        0,
        randf_range(-1, 1)
    ).normalized()
    
    var distance = randf_range(min_walk_distance, max_walk_distance)
    target_position = global_position + random_direction * distance
    
    navigation_agent.target_position = target_position
    is_moving = true

func _on_navigation_finished():
    is_moving = false
    await get_tree().create_timer(randf_range(1.0, 3.0)).timeout
    set_new_target()
