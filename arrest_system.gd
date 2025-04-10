class_name ArrestSystem
extends Area3D

@export var arrest_range: float = 2.5
@export var min_arrest_chance: float = 0.3
@export var max_arrest_chance: float = 0.9

var arrested_targets: Array = []

signal arrest_started(target)
signal arrest_succeeded(target)
signal arrest_failed(target)
signal target_resisted(target)

func attempt_arrest(target: Node) -> bool:
    if global_position.distance_to(target.global_position) > arrest_range:
        return false
    
    emit_signal("arrest_started", target)
    
    var arrest_chance = calculate_arrest_chance(target)
    var random_value = randf()
    
    if random_value <= arrest_chance:
        if target.has_method("surrender"):
            if target.surrender():
                arrested_targets.append(target)
                emit_signal("arrest_succeeded", target)
                return true
    else:
        emit_signal("arrest_failed", target)
        if target.has_method("resist_arrest"):
            target.resist_arrest()
            emit_signal("target_resisted", target)
    
    return false

func calculate_arrest_chance(target: Node) -> float:
    var base_chance = min_arrest_chance
    
    # Учитываем репутацию полиции
    var faction_system = get_node("/root/FactionSystem")
    if faction_system:
        var police_rep = faction_system.get_relation("police", target.faction)
        base_chance += (police_rep + 100) / 200 * (max_arrest_chance - min_arrest_chance)
    
    # Учитываем здоровье цели
    if target.has_method("get_health"):
        var health_percent = target.get_health() / 100.0
        base_chance *= 1.0 + (1.0 - health_percent) * 0.5
    
    return clamp(base_chance, min_arrest_chance, max_arrest_chance)

func release_prisoner(target: Node) -> bool:
    if arrested_targets.has(target):
        arrested_targets.erase(target)
        if target.has_method("release"):
            target.release()
        return true
    return false

func transport_prisoners_to_station(station_position: Vector3) -> int:
    var transported = 0
    for target in arrested_targets:
        if target.has_method("transport_to"):
            target.transport_to(station_position)
            transported += 1
    arrested_targets.clear()
    return transported
