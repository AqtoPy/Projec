class_name RoleBase
extends CharacterBody3D

# Общие свойства для всех ролей
@export var role_name: String = "base"
@export var move_speed: float = 5.0
@export var health: int = 100
@export var stamina: float = 100.0
@export var faction: String = "neutral"

var abilities: Dictionary = {}
var inventory: Array = []
var reputation: Dictionary = {}

func _ready():
    initialize_role()
    setup_faction()

func initialize_role():
    pass  # Переопределяется в дочерних классах

func setup_faction():
    # Инициализация репутации с другими фракциями
    reputation = {
        "police": 50,
        "gangs": 50,
        "media": 50,
        "military": 50
    }

func use_ability(ability_name: String):
    if abilities.has(ability_name) and abilities[ability_name].enabled:
        abilities[ability_name].use()
        return true
    return false

func take_damage(amount: int, source: Node = null):
    health -= amount
    if health <= 0:
        die()
    return health

func die():
    queue_free()
