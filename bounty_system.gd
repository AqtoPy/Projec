class_name BountySystem
extends Node

var wanted_list: Dictionary = {} # {player_id: {bounty: int, crimes: Array}}
var active_hunters: Array = []
var bounty_hunters_pool: Array = []

signal bounty_added(target, amount)
signal bounty_claimed(hunter, target, amount)
signal hunt_started(target)
signal hunt_ended(target)

func add_bounty(target: Node, bounty_amount: int, crime: String):
    if not target.has_method("get_id"):
        return false
    
    var target_id = target.get_id()
    
    if not wanted_list.has(target_id):
        wanted_list[target_id] = {
            "bounty": 0,
            "crimes": [],
            "target_ref": weakref(target)
        }
    
    wanted_list[target_id]["bounty"] += bounty_amount
    wanted_list[target_id]["crimes"].append(crime)
    
    emit_signal("bounty_added", target, bounty_amount)
    
    # Автоматически начинаем охоту при высоком bounty
    if wanted_list[target_id]["bounty"] >= 1000 and not active_hunters.has(target_id):
        start_hunt(target)
    
    return true

func start_hunt(target: Node) -> bool:
    if not target.has_method("get_id"):
        return false
    
    var target_id = target.get_id()
    
    if not wanted_list.has(target_id) or active_hunters.has(target_id):
        return false
    
    active_hunters.append(target_id)
    assign_hunters_to_target(target)
    emit_signal("hunt_started", target)
    return true

func assign_hunters_to_target(target: Node):
    var available_hunters = get_available_hunters()
    var hunters_to_assign = min(available_hunters.size(), 3) # Макс 3 охотника
    
    for i in range(hunters_to_assign):
        var hunter = available_hunters[i]
        if hunter.has_method("assign_hunt_target"):
            hunter.assign_hunt_target(target)

func get_available_hunters() -> Array:
    var available = []
    for hunter in bounty_hunters_pool:
        if is_instance_valid(hunter) and hunter.has_method("is_available") and hunter.is_available():
            available.append(hunter)
    return available

func claim_bounty(hunter: Node, target: Node) -> bool:
    if not target.has_method("get_id"):
        return false
    
    var target_id = target.get_id()
    
    if wanted_list.has(target_id) and active_hunters.has(target_id):
        var bounty_amount = wanted_list[target_id]["bounty"]
        
        if hunter.has_method("reward_money"):
            hunter.reward_money(bounty_amount)
        
        wanted_list.erase(target_id)
        active_hunters.erase(target_id)
        emit_signal("bounty_claimed", hunter, target, bounty_amount)
        emit_signal("hunt_ended", target)
        return true
    
    return false

func register_hunter(hunter: Node):
    if not bounty_hunters_pool.has(hunter):
        bounty_hunters_pool.append(hunter)
        return true
    return false

func end_hunt(target: Node) -> bool:
    if not target.has_method("get_id"):
        return false
    
    var target_id = target.get_id()
    
    if active_hunters.has(target_id):
        active_hunters.erase(target_id)
        emit_signal("hunt_ended", target)
        
        # Оповещаем охотников
        for hunter in bounty_hunters_pool:
            if is_instance_valid(hunter) and hunter.has_method("clear_hunt_target"):
                hunter.clear_hunt_target(target)
        
        return true
    return false
