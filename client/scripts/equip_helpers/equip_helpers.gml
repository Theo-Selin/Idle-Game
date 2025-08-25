/// add_to_inventory(_type, _amount) → bool
/// Adds to persisted inventory without any loot VFX.
function add_to_inventory(_type, _amount) {
    if (_amount <= 0) return true;

    // --- Ensure save path exists ---
    if (!is_struct(global.save)) global.save = {};
    if (!variable_struct_exists(global.save, "inventory") || !is_struct(global.save.inventory)) {
        global.save.inventory = {};
    }

    var have = inventory_count(_type);
    if (is_undefined(have)) have = 0;

    variable_struct_set(global.save.inventory, _type, have + _amount);

    global.__save_dirty    = true;
    global.__save_cooldown = global.__save_interval_steps;

    show_debug_message("📥 Added: " + string(_type) + " x" + string(_amount));
    return true;
}


/// equip_item(_item_id) → bool
/// Removes 1 from inventory and equips. If slot had an item, it is returned to inventory.
function equip_item(_item_id) {
    // --- Ensure save path exists ---
    if (!is_struct(global.save)) global.save = {};
    if (!variable_struct_exists(global.save, "equipment") || !is_struct(global.save.equipment)) {
        global.save.equipment = {};
    }

    var item = variable_struct_get(global.item_data, _item_id);
    if (is_undefined(item)) {
        show_debug_message("❌ equip_item: unknown item " + string(_item_id));
        return false;
    }

    // Default to "weapon" if no explicit slot on the item
    var slot_name = variable_struct_exists(item, "slot") ? item.slot : "weapon";

    // Already equipped? (no-op)
    var current_id = variable_struct_get(global.save.equipment, slot_name);
    if (!is_undefined(current_id) && current_id == _item_id) {
        return true;
    }

    // Must have at least 1 in inventory to equip
    if (inventory_count(_item_id) <= 0) {
        show_debug_message("❌ equip_item: no copies of " + string(_item_id) + " in inventory");
        return false;
    }

    // If slot already had an item, return it to inventory
    if (!is_undefined(current_id)) {
        add_to_inventory(current_id, 1);
    }

    // Consume one copy from inventory and equip the new one
    if (!remove_from_inventory(_item_id, 1)) {
        show_debug_message("❌ equip_item: failed to remove 1 from inventory for " + string(_item_id));
        return false;
    }

    variable_struct_set(global.save.equipment, slot_name, _item_id);

    // Keep alias synced + persist
    global.equipment_slots  = global.save.equipment;
    global.__save_dirty     = true;
    global.__save_cooldown  = global.__save_interval_steps;

    show_debug_message("✅ Equipped: " + string(_item_id) + " into " + string(slot_name));
    return true;
}


/// unequip_slot(_slot_name) → bool
/// Clears the slot and returns the item to inventory.
function unequip_slot(_slot_name) {
    // --- Ensure save path exists ---
    if (!is_struct(global.save)) global.save = {};
    if (!variable_struct_exists(global.save, "equipment") || !is_struct(global.save.equipment)) {
        global.save.equipment = {};
    }

    var current_id = variable_struct_get(global.save.equipment, _slot_name);
    if (is_undefined(current_id)) return false;

    // Return the item to inventory
    add_to_inventory(current_id, 1);

    // Clear the slot
    variable_struct_set(global.save.equipment, _slot_name, undefined);

    // Keep alias synced + persist
    global.equipment_slots  = global.save.equipment;
    global.__save_dirty     = true;
    global.__save_cooldown  = global.__save_interval_steps;

    show_debug_message("↩️ Unequipped " + string(current_id) + " from " + string(_slot_name));
    return true;
}
