class_name RandomEventSystem
extends Node

@export var min_event_delay: float = 120.0
@export var max_event_delay: float = 300.0

var possible_events: Array = [
    "police_raid",
    "gang_war",
    "car_chase",
    "witness_event",
    "item_drop"
]

var active_events: Dictionary = {}

signal event_triggered(event_name, location)
signal event_ended(event_name)
signal event_failed(event_name)

func _ready():
    $EventTimer.timeout.connect(_on_event_timer_timeout)
    start_event_timer()

func start_event_timer():
    $EventTimer.start(randf_range(min_event_delay, max_event_delay))

func _on_event_timer_timeout():
    trigger_random_event()
    start_event_timer()

func trigger_random_event():
    if possible_events.size() == 0:
        return
    
    var random_event = possible_events[randi() % possible_events.size()]
    var event_location = get_random_location()
    
    match random_event:
        "police_raid":
            start_police_raid(event_location)
        "gang_war":
            start_gang_war(event_location)
        "car_chase":
            start_car_chase(event_location)
        "witness_event":
            spawn_witness(event_location)
        "item_drop":
            spawn_item_drop(event_location)
    
    active_events[random_event] = {
        "start_time": Time.get_unix_time_from_system(),
        "location": event_location,
        "participants": []
    }
    
    emit_signal("event_triggered", random_event, event_location)

func start_police_raid(location: Vector3):
    var police_units = get_tree().get_nodes_in_group("police")
    var target_buildings = get_nearby_buildings(location, 20.0)
    
    for i in range(min(3, police_units.size())):
        if police_units[i].has_method("respond_to_raid"):
            police_units[i].respond_to_raid(target_buildings[0].global_position)

func start_gang_war(location: Vector3):
    var gangs = ["red_gang", "blue_gang"]
    for gang in gangs:
        var members = get_tree().get_nodes_in_group(gang)
        for i in range(min(2, members.size())):
            if members[i].has_method("start_gang_war"):
                members[i].start_gang_war(location)

func start_car_chase(location: Vector3):
    var criminals = get_tree().get_nodes_in_group("wanted")
    if criminals.size() > 0:
        var criminal = criminals[0]
        if criminal.has_method("flee_in_vehicle"):
            criminal.flee_in_vehicle()
            
            var police = get_tree().get_nodes_in_group("police")
            for i in range(min(2, police.size())):
                if police[i].has_method("pursuit_target"):
                    police[i].pursuit_target(criminal)

func spawn_witness(location: Vector3):
    var witness_scene = preload("res://characters/witness.tscn")
    var witness = witness_scene.instantiate()
    get_parent().add_child(witness)
    witness.global_position = location
    
    if witness.has_method("set_important_info"):
        var random_info = [
            "saw a murder",
            "knows about police corruption",
            "has evidence against gang leader"
        ]
        witness.set_important_info(random_info[randi() % random_info.size()])

func spawn_item_drop(location: Vector3):
    var item_types = ["weapon", "drugs", "money", "evidence"]
    var item_scene = preload("res://items/collectible_item.tscn")
    var item = item_scene.instantiate()
    get_parent().add_child(item)
    item.global_position = location
    item.set_item_type(item_types[randi() % item_types.size()])

func get_random_location() -> Vector3:
    var nav = get_tree().get_first_node_in_group("navigation")
    if nav:
        return nav.get_random_point()
    return Vector3.ZERO

func get_nearby_buildings(location: Vector3, radius: float) -> Array:
    var buildings = []
    var space = get_world_3d().direct_space_state
    var query = PhysicsShapeQueryParameters3D.new()
    query.shape = SphereShape3D.new()
    query.shape.radius = radius
    query.transform = Transform3D(Basis(), location)
    query.collision_mask = 2 # Building layer
    
    var results = space.intersect_shape(query)
    for result in results:
        buildings.append(result.collider)
    
    return buildings

func complete_event(event_name: String, success: bool = true):
    if active_events.has(event_name):
        active_events.erase(event_name)
        if success:
            emit_signal("event_ended", event_name)
        else:
            emit_signal("event_failed", event_name)
