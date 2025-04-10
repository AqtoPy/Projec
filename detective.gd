class_name Detective
extends RoleBase

@onready var clue_vision = $ClueVision
@onready var notebook = $Notebook

func _ready():
    role_name = "detective"
    move_speed = 5.2
    health = 90
    stamina = 110
    
    abilities = {
        "analyze_clue": {
            "enabled": true,
            "use": analyze_clue
        },
        "interrogate": {
            "enabled": true,
            "use": start_interrogation
        },
        "disguise": {
            "enabled": false,
            "use": toggle_disguise
        }
    }

func analyze_clue():
    if clue_vision:
        clue_vision.activate()
        return true
    return false

func start_interrogation(npc):
    if npc.has_method("respond_to_interrogation"):
        var info = npc.respond_to_interrogation(reputation)
        notebook.add_entry(npc.name, info)
        return info
    return null

func toggle_disguise():
    # Маскировка под другую фракцию
    if abilities["disguise"].enabled:
        var new_faction = "gangs" if faction == "police" else "police"
        set_faction(new_faction)
        return true
    return false

func set_faction(new_faction: String):
    faction = new_faction
    update_disguise()

func update_disguise():
    # Визуальное изменение внешности
    $Outfit.set_disguise(faction)
