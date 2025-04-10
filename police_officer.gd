class_name PoliceOfficer
extends RoleBase

@onready var arrest_system = $ArrestSystem
@onready var radio = $Radio

func _ready():
    role_name = "police"
    move_speed = 4.8
    health = 110
    faction = "police"
    
    abilities = {
        "arrest": {
            "enabled": true,
            "use": attempt_arrest
        },
        "call_backup": {
            "enabled": true,
            "use": call_backup
        },
        "access_database": {
            "enabled": true,
            "use": access_police_db
        }
    }

func attempt_arrest(target):
    if arrest_system and target.has_method("surrender"):
        var success = arrest_system.attempt_arrest(target, reputation["police"])
        if success:
            reputation["police"] += 2
            reputation["gangs"] -= 5
        return success
    return false

func call_backup():
    if radio:
        radio.request_backup(global_position)
        return true
    return false

func access_police_db(query: String):
    var db = get_node("/root/Game/PoliceDatabase")
    if db:
        return db.query(query)
    return null

func issue_fine(target, amount: int, reason: String):
    if target.has_method("receive_fine"):
        return target.receive_fine(amount, reason)
    return false
