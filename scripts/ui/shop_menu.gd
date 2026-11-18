extends CanvasLayer

signal return_requested

@onready var coin_label: Label = %CoinLabel
@onready var perk_container: TabContainer = %PerkContainer
@onready var purchase_button: Button = %PurchaseButton

var coins: int = 0
#var selected: ShopItem

func _ready() -> void:
    coins = SaveManager.total_stats.get(SaveManager.Stat.COINS, 0)
    update_coin_label(coins)

func populate_perk_container() -> void:
    pass

func update_coin_label(new_coins: int) -> void:
    coin_label.text = "Coins: %s" % new_coins

func _on_return_button_pressed() -> void:
    return_requested.emit()
    if get_parent() == get_tree().root:
        get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
    else:
        queue_free()

func _on_purchase_button_pressed() -> void:
    var confirm = preload("res://scenes/menus/confirm_menu.tscn").instantiate()
    confirm.confirmation_text = "Purchase?"
    confirm.confirmation_result.connect(_on_confirmation_result)
    add_child(confirm)

func _on_confirmation_result(confirmed: bool) -> void:
    if confirmed:
        purchase_item()
    else:
        print("Purchase cancelled")

func purchase_item() -> void:
    pass
