/// collect_loot(_type, _amount) → bool
/// Coins go to currency, other items go to inventory.
function collect_loot(_type, _amount) {
    var amt = max(0, floor(_amount));
    if (amt <= 0) return false;

    var item_key = string(_type); // ✅ don't use 'id'
    var def = variable_struct_get(global.item_data, item_key);
    if (is_undefined(def)) {
        show_debug_message("⚠️ Unknown item id in collect_loot: " + string(_type));
        return false;
    }

    // Currency routing
    if (item_key == "coin_copper" || item_key == "coin_bronze") {
        currency_add_bronze(amt);
        show_debug_message("📥 Collected bronze x" + string(amt));
        return true;
    } else if (item_key == "coin_silver") {
        currency_add_silver(amt);
        show_debug_message("📥 Collected silver x" + string(amt));
        return true;
    } else if (item_key == "coin_gold") {
        currency_add_gold(amt);
        show_debug_message("📥 Collected gold x" + string(amt));
        return true;
    }

    // Regular items → persisted inventory
    var cur = variable_struct_get(global.save.inventory, item_key);
    if (is_undefined(cur)) cur = 0;
    variable_struct_set(global.save.inventory, item_key, cur + amt);

    global.__save_dirty = true;
    global.__save_cooldown = global.__save_interval_steps;

    show_debug_message("📥 Collected: " + string(item_key) + " x" + string(amt));
    return true;
}
