/// remove_from_inventory(_type, _amount) → bool
/// Currency-aware spend; otherwise decrement item stack.
function remove_from_inventory(_type, _amount) {
    if (_amount <= 0) return true;

    var key = string(_type); // ✅ don't use 'id'

    // Currency spend
    if (key == "coin_copper" || key == "coin_bronze") {
        if (!currency_spend_bronze(_amount)) {
            show_debug_message("❌ Not enough BRONZE to remove " + string(_amount));
            return false;
        }
        global.__save_dirty = true;
        global.__save_cooldown = global.__save_interval_steps;
        show_debug_message("📤 Spent bronze: " + string(_amount));
        return true;
    }
    if (key == "coin_silver") {
        var need_b = _amount * 1000;
        if (!currency_spend_bronze(need_b)) {
            show_debug_message("❌ Not enough SILVER-equiv to remove " + string(_amount));
            return false;
        }
        global.__save_dirty = true;
        global.__save_cooldown = global.__save_interval_steps;
        show_debug_message("📤 Spent silver: " + string(_amount));
        return true;
    }
    if (key == "coin_gold") {
        var need_b2 = _amount * 1000000;
        if (!currency_spend_bronze(need_b2)) {
            show_debug_message("❌ Not enough GOLD-equiv to remove " + string(_amount));
            return false;
        }
        global.__save_dirty = true;
        global.__save_cooldown = global.__save_interval_steps;
        show_debug_message("📤 Spent gold: " + string(_amount));
        return true;
    }

    // Regular items
    var have = inventory_count(key);
    if (have < _amount) {
        show_debug_message("❌ Not enough " + key + " to remove " + string(_amount));
        return false;
    }

    variable_struct_set(global.save.inventory, key, have - _amount);
    global.__save_dirty = true;
    global.__save_cooldown = global.__save_interval_steps;

    show_debug_message("📤 Removed: " + key + " x" + string(_amount));
    return true;
}
