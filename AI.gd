extends CharacterBody3D

class_name SmartAI

# Настройки ИИ
enum AI_STATE {
    PATROL,
    INVESTIGATE,
    COMBAT,
    FLEE
}

@export var move_speed: float = 3.5
@export var run_speed: float = 5.0
@export var rotation_speed: float = 8.0
@export var vision_range: float = 15.0
@export var vision_angle: float = 120.0
@export var hearing_range: float = 10.0
@export var suspicion_threshold: float = 70.0
@export var health: int = 100

var current_state: AI_STATE = AI_STATE.PATROL
var target: Node3D = null
var navigation_agent: NavigationAgent3D
var path: PackedVector3Array = []
var suspicion_level: float = 0.0
var last_known_position: Vector3 = Vector3.ZERO
var cover_points: Array = []
var current_cover: Node3D = null
var faction: String = "police"
var known_traitors: Array = []

# Оружие
@onready var weapon: Node3D = $Weapon
var can_shoot: bool = true
var shoot_cooldown: float = 0.5

func _ready():
    navigation_agent = $NavigationAgent3D
    $VisionArea/CollisionShape3D.shape.radius = vision_range
    $HearingArea/CollisionShape3D.shape.radius = hearing_range
    
    # Инициализация точек патрулирования
    initialize_patrol_points()
    
    # Подключаем сигналы
    $VisionArea.body_entered.connect(_on_vision_area_body_entered)
    $HearingArea.body_entered.connect(_on_hearing_area_body_entered)
    navigation_agent.navigation_finished.connect(_on_navigation_finished)

func _physics_process(delta):
    match current_state:
        AI_STATE.PATROL:
            patrol_behavior(delta)
        AI_STATE.INVESTIGATE:
            investigate_behavior(delta)
        AI_STATE.COMBAT:
            combat_behavior(delta)
        AI_STATE.FLEE:
            flee_behavior(delta)
    
    move_and_slide()
    update_suspicion(delta)

func initialize_patrol_points():
    # Находим все точки патрулирования на карте
    var patrol_group = get_tree().get_nodes_in_group("patrol_points")
    for point in patrol_group:
        if point.faction == faction:
            cover_points.append(point)

func patrol_behavior(delta):
    if navigation_agent.is_navigation_finished():
        # Выбираем случайную точку патрулирования
        if cover_points.size() > 0:
            var random_point = cover_points[randi() % cover_points.size()]
            navigation_agent.target_position = random_point.global_position
    
    # Плавное движение к цели
    var next_path_pos = navigation_agent.get_next_path_position()
    var direction = (next_path_pos - global_position).normalized()
    velocity = direction * move_speed
    
    # Плавный поворот
    if direction.length() > 0.1:
        var look_dir = Vector3(direction.x, 0, direction.z)
        var target_rotation = atan2(look_dir.x, look_dir.z)
        rotation.y = lerp_angle(rotation.y, target_rotation, delta * rotation_speed)
    
    # Проверка на подозрительную активность
    if suspicion_level > 30.0:
        transition_to(AI_STATE.INVESTIGATE)

func investigate_behavior(delta):
    if target:
        # Если есть цель, переходим в режим боя
        transition_to(AI_STATE.COMBAT)
        return
    
    if last_known_position != Vector3.ZERO:
        # Двигаемся к последнему известному положению
        navigation_agent.target_position = last_known_position
        
        var next_path_pos = navigation_agent.get_next_path_position()
        var direction = (next_path_pos - global_position).normalized()
        velocity = direction * move_speed
        
        if (global_position.distance_to(last_known_position) < 2.0:
            # Осматриваемся
            rotation.y += delta * 1.0
            suspicion_level -= delta * 10.0
            
            if suspicion_level < 20.0:
                last_known_position = Vector3.ZERO
                transition_to(AI_STATE.PATROL)
    else:
        # Случайный поиск
        rotation.y += delta * 1.5
        suspicion_level -= delta * 5.0
        
        if suspicion_level < 10.0:
            transition_to(AI_STATE.PATROL)

func combat_behavior(delta):
    if !target or !is_instance_valid(target):
        transition_to(AI_STATE.INVESTIGATE)
        return
    
    # Определяем, является ли цель предателем
    var is_traitor = known_traitors.has(target) or evaluate_target(target)
    
    if is_traitor:
        # Тактика против предателя
        engage_target(target, delta)
    else:
        # Тактика против обычного врага
        basic_combat(target, delta)

func engage_target(target_node: Node3D, delta):
    # Вычисляем дистанцию до цели
    var distance_to_target = global_position.distance_to(target_node.global_position)
    
    # Выбираем тактику в зависимости от расстояния
    if distance_to_target > vision_range * 0.7:
        # Дальний бой - ищем укрытие и стреляем
        find_cover()
        if can_shoot and has_line_of_sight(target_node):
            shoot_at(target_node)
    else:
        # Ближний бой - агрессивное преследование
        navigation_agent.target_position = target_node.global_position
        var next_path_pos = navigation_agent.get_next_path_position()
        var direction = (next_path_pos - global_position).normalized()
        velocity = direction * run_speed
        
        if can_shoot and has_line_of_sight(target_node):
            shoot_at(target_node)
    
    # Если здоровье низкое - отступаем
    if health < 30:
        transition_to(AI_STATE.FLEE)

func basic_combat(target_node: Node3D, delta):
    # Более осторожная тактика для обычных целей
    find_cover()
    
    if can_shoot and has_line_of_sight(target_node):
        shoot_at(target_node)
    
    # Периодически меняем позицию
    if randf() < 0.01:
        navigation_agent.target_position = get_random_position_nearby(5.0)

func flee_behavior(delta):
    # Ищем ближайшее безопасное место
    var safe_spot = find_safe_spot()
    if safe_spot:
        navigation_agent.target_position = safe_spot.global_position
        
        var next_path_pos = navigation_agent.get_next_path_position()
        var direction = (next_path_pos - global_position).normalized()
        velocity = direction * run_speed
        
        # Если далеко от опасности и здоровье восстановлено
        if health > 70 and (target == null or global_position.distance_to(target.global_position) > vision_range * 1.5):
            transition_to(AI_STATE.PATROL)
    else:
        # Если не нашли безопасное место - просто убегаем
        velocity = -global_transform.basis.z * run_speed

func find_cover():
    if current_cover and randf() > 0.3:
        return  # 70% шанс остаться в укрытии
    
    var best_cover = null
    var best_score = -1.0
    
    for cover in cover_points:
        if cover == current_cover:
            continue
            
        var score = evaluate_cover(cover)
        if score > best_score:
            best_score = score
            best_cover = cover
    
    if best_cover:
        current_cover = best_cover
        navigation_agent.target_position = best_cover.global_position

func evaluate_cover(cover: Node3D) -> float:
    var score = 0.0
    
    # Учитываем расстояние до укрытия
    var distance = global_position.distance_to(cover.global_position)
    score += 1.0 / (distance + 0.1)
    
    # Учитываем защиту от цели
    if target:
        var cover_dir = (cover.global_position - target.global_position).normalized()
        var to_target = (target.global_position - global_position).normalized()
        var dot = cover_dir.dot(to_target)
        score += max(0.0, dot) * 2.0
    
    return score

func find_safe_spot():
    var safe_spots = get_tree().get_nodes_in_group("safe_zones")
    if safe_spots.size() > 0:
        return safe_spots[randi() % safe_spots.size()]
    return null

func shoot_at(target_node: Node3D):
    if !can_shoot or !weapon:
        return
    
    # Наводимся на цель
    var direction = (target_node.global_position - weapon.global_position).normalized()
    weapon.look_at(weapon.global_position + direction, Vector3.UP)
    
    # Стреляем
    weapon.shoot()
    can_shoot = false
    await get_tree().create_timer(shoot_cooldown).timeout
    can_shoot = true

func has_line_of_sight(target_node: Node3D) -> bool:
    var space_state = get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(
        weapon.global_position,
        target_node.global_position,
        1
    )
    query.exclude = [self]
    
    var result = space_state.intersect_ray(query)
    return result.is_empty() or result.collider == target_node

func evaluate_target(target_node: Node3D) -> bool:
    # Проверяем, является ли цель предателем
    if target_node.has_method("get_faction") and target_node.get_faction() == faction:
        # Проверяем подозрительное поведение
        var suspicious_actions = 0
        
        if target_node.global_position.distance_to(global_position) < 5.0 and target_node.velocity.length() > 3.0:
            suspicious_actions += 1  # Бег вблизи союзников
        
        if target_node.has_method("is_shooting") and target_node.is_shooting():
            var shooting_target = target_node.get_shooting_target()
            if shooting_target and shooting_target.get_faction() == faction:
                suspicious_actions += 2  # Стрельба по своим
        
        return suspicious_actions >= 2
    return false

func take_damage(amount: int, attacker: Node3D = null):
    health -= amount
    if health <= 0:
        die()
        return
    
    if attacker:
        if attacker.get_faction() == faction:
            # Если атаковал свой - добавляем в список предателей
            if !known_traitors.has(attacker):
                known_traitors.append(attacker)
                communicate_traitor(attacker)
        
        last_known_position = attacker.global_position
        target = attacker
        suspicion_level = 100.0
        transition_to(AI_STATE.COMBAT)

func die():
    queue_free()

func communicate_traitor(traitor: Node3D):
    # Сообщаем другим ИИ о предателе
    var allies = get_tree().get_nodes_in_group(faction)
    for ally in allies:
        if ally != self and ally.has_method("receive_traitor_info"):
            ally.receive_traitor_info(traitor)

func receive_traitor_info(traitor: Node3D):
    if !known_traitors.has(traitor):
        known_traitors.append(traitor)
        suspicion_level += 30.0
        
        if current_state == AI_STATE.PATROL:
            transition_to(AI_STATE.INVESTIGATE)

func transition_to(new_state: AI_STATE):
    exit_state(current_state)
    current_state = new_state
    enter_state(new_state)

func enter_state(new_state: AI_STATE):
    match new_state:
        AI_STATE.PATROL:
            $StateLabel.text = "Patrol"
        AI_STATE.INVESTIGATE:
            $StateLabel.text = "Investigate"
        AI_STATE.COMBAT:
            $StateLabel.text = "Combat"
        AI_STATE.FLEE:
            $StateLabel.text = "Flee"

func exit_state(old_state: AI_STATE):
    pass

func _on_vision_area_body_entered(body: Node3D):
    if body == self or !body.has_method("get_faction"):
        return
    
    # Проверяем угол обзора
    var direction = (body.global_position - global_position).normalized()
    var forward = -global_transform.basis.z
    var angle = rad_to_deg(forward.angle_to(direction))
    
    if angle > vision_angle / 2.0:
        return  # Вне поля зрения
    
    # Проверяем видимость
    if !has_line_of_sight(body):
        return
    
    # Оцениваем цель
    var is_enemy = body.get_faction() != faction
    var is_traitor = evaluate_target(body)
    
    if is_enemy or is_traitor:
        target = body
        last_known_position = body.global_position
        suspicion_level = 100.0
        transition_to(AI_STATE.COMBAT)
    elif body.velocity.length() > 4.0:
        # Подозрительное поведение
        suspicion_level += 30.0
        last_known_position = body.global_position
        if current_state == AI_STATE.PATROL:
            transition_to(AI_STATE.INVESTIGATE)

func _on_hearing_area_body_entered(body: Node3D):
    if body == self or !body.has_method("get_faction"):
        return
    
    if body.has_method("is_shooting") and body.is_shooting():
        # Слышим выстрелы
        suspicion_level += 20.0
        last_known_position = body.global_position
        
        if current_state == AI_STATE.PATROL and suspicion_level > 40.0:
            transition_to(AI_STATE.INVESTIGATE)

func _on_navigation_finished():
    if current_state == AI_STATE.PATROL:
        # Выбираем новую точку патрулирования
        if cover_points.size() > 0:
            var random_point = cover_points[randi() % cover_points.size()]
            navigation_agent.target_position = random_point.global_position

func update_suspicion(delta):
    if current_state == AI_STATE.PATROL:
        suspicion_level = max(0.0, suspicion_level - delta * 2.0)
    elif current_state == AI_STATE.INVESTIGATE:
        suspicion_level = max(0.0, suspicion_level - delta * 1.0)

func get_random_position_nearby(radius: float) -> Vector3:
    var random_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
    return global_position + random_dir * radius

func get_faction() -> String:
    return faction
