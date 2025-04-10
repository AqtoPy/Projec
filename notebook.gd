class_name Notebook
extends Node

var clues: Dictionary = {}
var suspects: Dictionary = {}
var case_notes: Dictionary = {}
var current_case: String = ""

signal clue_added(clue_data)
signal suspect_identified(suspect_data)
signal case_solved(case_name)

func _ready():
    load_default_cases()

func load_default_cases():
    case_notes["Main"] = {
        "description": "Investigate corruption in the city",
        "status": "active"
    }
    current_case = "Main"

func add_clue(clue_data: Dictionary):
    if not clues.has(current_case):
        clues[current_case] = []
    
    # Проверяем на дубликаты
    for existing_clue in clues[current_case]:
        if existing_clue["id"] == clue_data["id"]:
            return false
    
    clues[current_case].append(clue_data)
    emit_signal("clue_added", clue_data)
    
    # Автоматическая связь с подозреваемыми
    if clue_data.has("linked_suspects"):
        for suspect_id in clue_data["linked_suspects"]:
            link_clue_to_suspect(clue_data["id"], suspect_id)
    
    return true

func add_suspect(suspect_data: Dictionary):
    if not suspects.has(suspect_data["id"]):
        suspects[suspect_data["id"]] = suspect_data
        emit_signal("suspect_identified", suspect_data)
        return true
    return false

func link_clue_to_suspect(clue_id: String, suspect_id: String):
    if suspects.has(suspect_id) and clues.has(current_case):
        if not suspects[suspect_id].has("linked_clues"):
            suspects[suspect_id]["linked_clues"] = []
        
        if not clue_id in suspects[suspect_id]["linked_clues"]:
            suspects[suspect_id]["linked_clues"].append(clue_id)
            return true
    return false

func solve_case(case_name: String):
    if case_notes.has(case_name):
        case_notes[case_name]["status"] = "solved"
        emit_signal("case_solved", case_name)
        return true
    return false

func create_new_case(case_name: String, description: String):
    if not case_notes.has(case_name):
        case_notes[case_name] = {
            "description": description,
            "status": "active"
        }
        return true
    return false

func get_connected_clues(suspect_id: String) -> Array:
    if suspects.has(suspect_id) and suspects[suspect_id].has("linked_clues"):
        var result = []
        for clue_id in suspects[suspect_id]["linked_clues"]:
            for case in clues:
                for clue in clues[case]:
                    if clue["id"] == clue_id:
                        result.append(clue)
        return result
    return []

func generate_report() -> Dictionary:
    var report = {
        "case": current_case,
        "clues_count": clues[current_case].size() if clues.has(current_case) else 0,
        "suspects_count": suspects.size(),
        "status": case_notes[current_case]["status"] if case_notes.has(current_case) else "unknown"
    }
    return report
