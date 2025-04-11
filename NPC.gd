extends CharacterBody3D
   
   @export var speed: float = 3.0
   var target_position: Vector3
   var navigation_agent: NavigationAgent3D
   
   func _ready():
       navigation_agent = $NavigationAgent3D
       set_new_target()
   
   func _physics_process(delta):
       if navigation_agent.is_navigation_finished():
           set_new_target()
           return
       
       var next_pos = navigation_agent.get_next_path_position()
       var direction = (next_pos - global_position).normalized()
       velocity = direction * speed
       move_and_slide()
   
   func set_new_target():
       var random_point = Vector3(
           randf_range(-10, 10),
           0,
           randf_range(-10, 10)
       navigation_agent.target_position = random_point
