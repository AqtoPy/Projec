extends Node

# Подключаем ИИ к системе ролей и фракций
func setup_ai_with_role(ai_node, role_node):
    # Копируем свойства роли
    ai_node.faction = role_node.faction
    ai_node.reputation = role_node.reputation.duplicate()
    
    # Настраиваем специфичное поведение
    match role_node.role_name:
        "police":
            ai_node.vision_range = 18.0
            ai_node.hearing_range = 12.0
            ai_node.setup_police_behavior()
        "detective":
            ai_node.vision_range = 20.0
            ai_node.hearing_range = 15.0
            ai_node.setup_detective_behavior()
        "journalist":
            ai_node.vision_range = 15.0
            ai_node.hearing_range = 20.0
            ai_node.setup_journalist_behavior()
    
    # Подключаем сигналы
    role_node.connect("faction_changed", ai_node.update_faction)
    role_node.connect("reputation_updated", ai_node.update_reputation)

func setup_faction_ai(faction_name: String):
    var faction_system = get_node("/root/Game/FactionSystem")
    var members = faction_system.get_faction_members(faction_name)
    
    for member in members:
        if member.has_method("setup_faction_behavior"):
            member.setup_faction_behavior(faction_name)
