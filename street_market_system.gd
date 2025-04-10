class_name StreetMarket
extends Node3D

@export var illegal_items: Array[String] = ["weapon", "drugs", "stolen_goods"]
@export var legal_items: Array[String] = ["food", "clothes", "tools"]
@export var police_raid_chance: float = 0.2

var current_items: Dictionary = {}
var active_deals: Array = []
var is_raided: bool = false

signal item_added(item_name, price)
signal deal_started(buyer, item)
signal deal_completed(buyer, item)
signal police_raid_started
signal market_closed

func _ready():
    generate_items()
    $RaidTimer.timeout.connect(_on_raid_timer_timeout)
    $RaidTimer.start(randf_range(300.0, 600.0)) # Рейд через 5-10 минут

func generate_items():
    for item in illegal_items:
        var price = randf_range(50.0, 200.0)
        current_items[item] = {
            "price": price,
            "stock": randi_range(1, 5),
            "legal": false
        }
        emit_signal("item_added", item, price)
    
    for item in legal_items:
        var price = randf_range(10.0, 50.0)
        current_items[item] = {
            "price": price,
            "stock": randi_range(3, 10),
            "legal": true
        }
        emit_signal("item_added", item, price)

func attempt_purchase(buyer: Node, item_name: String) -> bool:
    if is_raided:
        return false
    
    if not current_items.has(item_name) or current_items[item_name]["stock"] <= 0:
        return false
    
    emit_signal("deal_started", buyer, item_name)
    
    # Проверка на полицейского под прикрытием
    if buyer.has_method("is_undercover") and buyer.is_undercover() and !current_items[item_name]["legal"]:
        start_police_raid()
        return false
    
    if buyer.has_method("spend_money"):
        if buyer.spend_money(current_items[item_name]["price"]):
            current_items[item_name]["stock"] -= 1
            give_item_to_buyer(buyer, item_name)
            emit_signal("deal_completed", buyer, item_name)
            return true
    
    return false

func give_item_to_buyer(buyer: Node, item_name: String):
    if buyer.has_method("receive_item"):
        buyer.receive_item(item_name)
    
    if !current_items[item_name]["legal"] and buyer.faction == "police":
        start_police_raid()

func start_police_raid():
    if is_raided:
        return
    
    is_raided = true
    emit_signal("police_raid_started")
    
    # Оповещаем всех на рынке
    for dealer in get_tree().get_nodes_in_group("market_dealers"):
        if dealer.has_method("flee_from_raid"):
            dealer.flee_from_raid()
    
    $MarketCloseTimer.start(120.0) # Рынок закрыт 2 минуты

func _on_raid_timer_timeout():
    if randf() <= police_raid_chance:
        start_police_raid()
    $RaidTimer.start(randf_range(300.0, 600.0))

func _on_market_close_timer_timeout():
    is_raided = false
    generate_items() # Обновляем товары
    emit_signal("market_closed")
