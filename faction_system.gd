extends Node
class_name FactionSystem

signal faction_relation_changed(faction1, faction2, new_value)
signal member_added(faction, member)
signal member_removed(faction, member)
signal traitor_reported(faction, traitor)

var factions: Dictionary = {
    "police": {
        "name": "Police Department",
        "members": [],
        "relations": {
            "gangs": -40,
            "media": 20,
            "military": 30,
            "civilian": 50
        },
        "traitors": []
    },
    "gangs": {
        "name": "Street Gangs",
        "members": [],
        "relations": {
            "police": -40,
            "media": -20,
            "military": -30,
            "civilian": -10
        },
        "traitors": []
    },
    "media": {
        "name": "Press Corps",
        "members": [],
        "relations": {
            "police": 20,
            "gangs": -20,
            "military": 0,
            "civilian": 30
        },
        "traitors": []
    },
    "military": {
        "name": "Military Forces",
        "members": [],
        "relations": {
            "police": 30,
            "gangs": -30,
            "media": 0,
            "civilian": 10
        },
        "traitors": []
    },
    "civilian": {
        "name": "Civilians",
        "members": [],
        "relations": {
            "police": 50,
            "gangs": -10,
            "media": 30,
            "military": 10
        },
        "traitors": []
    }
}

func register_member(member: Node, faction: String) -> bool:
    if not factions.has(faction):
        return false
    
    if not member in factions[faction]["members"]:
        factions[faction]["members"].append(member)
        member.faction = faction
        emit_signal("member_added", faction, member)
        return true
    return false

func unregister_member(member: Node) -> bool:
    var faction = member.faction
    if factions.has(faction):
        if member in factions[faction]["members"]:
            factions[faction]["members"].erase(member)
            emit_signal("member_removed", faction, member)
            return true
    return false

func get_relation(faction1: String, faction2: String) -> int:
    if factions.has(faction1) and factions[faction1]["relations"].has(faction2):
        return factions[faction1]["relations"][faction2]
    return 0

func set_relation(faction1: String, faction2: String, value: int) -> void:
    if factions.has(faction1) and factions[faction1]["relations"].has(faction2):
        factions[faction1]["relations"][faction2] = clamp(value, -100, 100)
        emit_signal("faction_relation_changed", faction1, faction2, value)

func modify_relation(faction1: String, faction2: String, delta: int) -> void:
    if factions.has(faction1) and factions[faction1]["relations"].has(faction2):
        factions[faction1]["relations"][faction2] = clamp(
            factions[faction1]["relations"][faction2] + delta, -100, 100
        )
        emit_signal("faction_relation_changed", faction1, faction2, factions[faction1]["relations"][faction2])

func report_traitor(member: Node) -> bool:
    var faction = member.faction
    if factions.has(faction):
        if not member in factions[faction]["traitors"]:
            factions[faction]["traitors"].append(member)
            emit_signal("traitor_reported", faction, member)
            
            # Уведомляем всех членов фракции
            for other_member in factions[faction]["members"]:
                if other_member.has_method("on_traitor_reported"):
                    other_member.on_traitor_reported(member)
            
            return true
    return false

func is_traitor(member: Node) -> bool:
    var faction = member.faction
    if factions.has(faction):
        return member in factions[faction]["traitors"]
    return false

func get_faction_members(faction: String) -> Array:
    if factions.has(faction):
        return factions[faction]["members"].duplicate()
    return []

func get_random_enemy_faction(for_faction: String) -> String:
    var enemy_factions = []
    for faction in factions[for_faction]["relations"]:
        if factions[for_faction]["relations"][faction] < 0:
            enemy_factions.append(faction)
    
    if enemy_factions.size() > 0:
        return enemy_factions[randi() % enemy_factions.size()]
    return ""
