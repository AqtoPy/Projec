extends CharacterBody3D
class_name Player

# Настройки
@export var move_speed: float = 5.0
@export var sprint_speed: float = 7.5
@export var jump_force: float = 4.5
@export var mouse_sensitivity: float = 0.002
@export var health: int = 100
@export var money: int = 500

# Компоненты
@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D
@onready var name_label = $NameLabel
@onready var money_label = $MoneyLabel
@onready var interaction_ray = $CameraPivot/Camera3D/InteractionRay

var current_role: String = "civilian"
var faction: String = "civilian"
var inventory: Array = []
var is_sprinting: bool = false
var can_move: bool = true

func _ready():
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    update_ui()
    FactionSystem.register_member(self, faction)

func _process(delta):
    if Input.is_action_just_pressed("ui_cancel"):
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    
    handle_interaction()

func _physics_process(delta):
    if not can_move:
        return
    
    # Движение
    var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    
    if direction:
        velocity.x = direction.x * (sprint_speed if is_sprinting else move_speed)
        velocity.z = direction.z * (sprint_speed if is_sprinting else move_speed)
    else:
        velocity.x = move_toward(velocity.x, 0, move_speed)
        velocity.z = move_toward(velocity.z, 0, move_speed)
    
    # Прыжок
    if is_on_floor() and Input.is_action_just_pressed("jump"):
        velocity.y = jump_force
    
    velocity.y -= 9.8 * delta
    move_and_slide()

func _input(event):
    if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * mouse_sensitivity)
        camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
        camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI/2, PI/2)
    
    if event.is_action_pressed("sprint"):
        is_sprinting = true
    elif event.is_action_released("sprint"):
        is_sprinting = false

func handle_interaction():
    if Input.is_action_just_pressed("interact") and interaction_ray.is_colliding():
        var collider = interaction_ray.get_collider()
        if collider.has_method("interact"):
            collider.interact(self)

func update_ui():
    name_label.text = "Player (%s)" % current_role
    money_label.text = "$%d" % money

func add_money(amount: int):
    money += amount
    update_ui()

func spend_money(amount: int) -> bool:
    if money >= amount:
        money -= amount
        update_ui()
        return true
    return false

func change_role(new_role: String):
    current_role = new_role
    update_ui()

func take_damage(amount: int, attacker: Node = null):
    health -= amount
    if health <= 0:
        die()

func die():
    # Обработка смерти игрока
    pass

func get_id() -> String:
    return str(get_instance_id())
