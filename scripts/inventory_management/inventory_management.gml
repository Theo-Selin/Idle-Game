/// ensure_inventory_order(_category)
function ensure_inventory_order(_category) {
    // Resolve/save -> local
    var _save = variable_struct_exists(global, "save") ? variable_struct_get(global, "save") : undefined;
    if (!is_struct(_save)) { _save = {}; global.save = _save; }

    // Resolve inventory_order -> local
    var _inv_order = variable_struct_exists(_save, "inventory_order") ? variable_struct_get(_save, "inventory_order") : undefined;
    if (!is_struct(_inv_order)) { _inv_order = {}; variable_struct_set(_save, "inventory_order", _inv_order); }

    // Fetch order array for this category
    var order = variable_struct_get(_inv_order, _category);
    if (is_undefined(order)) {
        order = [];
        variable_struct_set(_inv_order, _category, order);
    }

    // Build present items (>0) in this category
    var names = variable_struct_get_names(global.item_data);
    var present = [];
    for (var i = 0; i < array_length(names); i++) {
        var item_id = names[i];
        var item = variable_struct_get(global.item_data, item_id);
        if (string_lower(item.category) == string_lower(_category)) {
            var amt = inventory_count(item_id);
            if (amt > 0) array_push(present, item_id);
        }
    }

    // Remove entries no longer present
    var cleaned = [];
    for (var j = 0; j < array_length(order); j++) {
        var _id = order[j];
        if (array_contains(present, _id)) array_push(cleaned, _id);
    }

    // Append new present items not yet in order
    for (var k = 0; k < array_length(present); k++) {
        var _id2 = present[k];
        if (!array_contains(cleaned, _id2)) array_push(cleaned, _id2);
    }

    variable_struct_set(_inv_order, _category, cleaned);
    return cleaned;
}


/// array_contains(arr, value)
function array_contains(arr, value) {
    for (var i = 0; i < array_length(arr); i++) if (arr[i] == value) return true;
    return false;
}

/// inventory_swap_positions(_category, _idx_a, _idx_b)
function inventory_swap_positions(_category, _idx_a, _idx_b) {
    var order = ensure_inventory_order(_category);
    if (_idx_a < 0 || _idx_b < 0) return false;
    if (_idx_a >= array_length(order) || _idx_b >= array_length(order)) return false;

    var tmp = order[_idx_a];
    order[_idx_a] = order[_idx_b];
    order[_idx_b] = tmp;

    variable_struct_set(global.save.inventory_order, _category, order);
    global.__save_dirty = true;
    global.__save_cooldown = global.__save_interval_steps;
    return true;
}

/// sort_inventory_category(_category)
function sort_inventory_category(_category) {
    var order = ensure_inventory_order(_category);

    var pairs = [];
    for (var i = 0; i < array_length(order); i++) {
        var _id = order[i];
        var meta = variable_struct_get(global.item_data, _id);
        var nm = is_undefined(meta.name) ? _id : string(meta.name);
        array_push(pairs, { id: _id, name: string_lower(nm) });
    }

    // insertion sort (cheap & stable)
    for (var j = 1; j < array_length(pairs); j++) {
        var key = pairs[j];
        var k = j - 1;
        while (k >= 0 && pairs[k].name > key.name) {
            pairs[k + 1] = pairs[k];
            k--;
        }
        pairs[k + 1] = key;
    }

    var sorted = [];
    for (var t = 0; t < array_length(pairs); t++) array_push(sorted, pairs[t].id);
    variable_struct_set(global.save.inventory_order, _category, sorted);
    global.__save_dirty = true;
    global.__save_cooldown = global.__save_interval_steps;
    return true;
}

// ======================
// Currency (Bronze/Silver/Gold) 1000:1 carry
// ======================
function currency_init() {
    if (!variable_struct_exists(global, "save")) global.save = {};
    if (!variable_struct_exists(global.save, "currency")) global.save.currency = {};
    if (is_undefined(variable_struct_get(global.save.currency, "bronze"))) variable_struct_set(global.save.currency, "bronze", 0);
    if (is_undefined(variable_struct_get(global.save.currency, "silver"))) variable_struct_set(global.save.currency, "silver", 0);
    if (is_undefined(variable_struct_get(global.save.currency, "gold")))   variable_struct_set(global.save.currency, "gold", 0);
}

function currency_normalize() {
    currency_init();
    var cur = global.save.currency;

    var bronze = max(0, floor(variable_struct_get(cur, "bronze")));
    var silver = max(0, floor(variable_struct_get(cur, "silver")));
    var gold   = max(0, floor(variable_struct_get(cur, "gold")));

    silver += bronze div 1000;  bronze = bronze mod 1000;
    gold   += silver div 1000;  silver = silver mod 1000;

    variable_struct_set(cur, "bronze", bronze);
    variable_struct_set(cur, "silver", silver);
    variable_struct_set(cur, "gold", gold);

    global.__save_dirty = true;
    global.__save_cooldown = global.__save_interval_steps;
}

/// Add bronze (with carry to silver/gold)
function currency_add_bronze(_bronze) {
    currency_init();
    var cur = global.save.currency;
    var b = max(0, floor(_bronze));
    variable_struct_set(cur, "bronze", max(0, floor(variable_struct_get(cur, "bronze"))) + b);
    currency_normalize();
}

/// Add silver (with carry)
function currency_add_silver(_silver) {
    currency_init();
    var cur = global.save.currency;
    var s = max(0, floor(_silver));
    variable_struct_set(cur, "silver", max(0, floor(variable_struct_get(cur, "silver"))) + s);
    currency_normalize();
}

/// Add gold (with carry-safe normalize)
function currency_add_gold(_gold) {
    currency_init();
    var cur = global.save.currency;
    var g = max(0, floor(_gold));
    variable_struct_set(cur, "gold", max(0, floor(variable_struct_get(cur, "gold"))) + g);
    currency_normalize();
}

/// Total bronze equivalent (gold & silver converted)
function currency_total_bronze() {
    currency_init();
    var cur = global.save.currency;
    var b = max(0, floor(variable_struct_get(cur, "bronze")));
    var s = max(0, floor(variable_struct_get(cur, "silver")));
    var g = max(0, floor(variable_struct_get(cur, "gold")));
    return b + s * 1000 + g * 1000000;
}

/// Spend N bronze across denominations
function currency_spend_bronze(_amount) {
    var need = max(0, floor(_amount));
    var total = currency_total_bronze();
    if (need <= 0) return true;
    if (total < need) return false;

    var remain = total - need;
    var cur = global.save.currency;
    variable_struct_set(cur, "bronze", remain);
    variable_struct_set(cur, "silver", 0);
    variable_struct_set(cur, "gold",   0);
    currency_normalize();
    return true;
}

/// Snapshot accessor
function currency_get_bsg() {
    currency_init();
    return {
        bronze: variable_struct_get(global.save.currency, "bronze"),
        silver: variable_struct_get(global.save.currency, "silver"),
        gold:   variable_struct_get(global.save.currency, "gold")
    };
}

// (Optional legacy) add_gold – keep for compatibility, normalizes after write
function add_gold(_amount) {
    currency_init();
    var cur = global.save.currency;
    var g = variable_struct_get(cur, "gold");
    if (is_undefined(g)) g = 0;
    g += max(0, floor(_amount));
    variable_struct_set(cur, "gold", g);
    currency_normalize();
}

// ======================
// Selling (uses bronze price)
// ======================
function inv_get_sell_price_bronze(_item_id)
{
    var item = variable_struct_get(global.item_data, _item_id);
    if (is_undefined(item) || !is_struct(item)) return undefined;

    // Treat coins/currencies as non-sellable unless explicitly priced
    var is_currency = false;
    if (variable_struct_exists(item, "is_currency") && item.is_currency) is_currency = true;
    else if (is_string(_item_id) && string_copy(_item_id, 1, 5) == "coin_") is_currency = true;
    if (is_currency) return undefined;

    // Only use an explicit price field; no fallbacks
    if (variable_struct_exists(item, "sell_bronze") && is_real(item.sell_bronze) && item.sell_bronze > 0) {
        return floor(item.sell_bronze);
    }
    if (variable_struct_exists(item, "sell_price") && is_real(item.sell_price) && item.sell_price > 0) {
        return floor(item.sell_price);
    }

    // No explicit price -> no price shown
    return undefined;
}

function inv_sell_one(_item_id) {
    if (inventory_count(_item_id) <= 0) return false;
    if (!remove_from_inventory(_item_id, 1)) return false;

    var bronze = inv_get_sell_price_bronze(_item_id);
    currency_add_bronze(bronze);

    show_debug_message("💰 Sold 1x " + string(_item_id) + " for " + string(bronze) + " bronze");
    return true;
}

/// currency_bronze_to_bsg(_bronze) → {gold,silver,bronze}
function currency_bronze_to_bsg(_bronze) {
    var total = max(0, floor(_bronze));
    var gold   = total div 1000000;
    var rem    = total mod 1000000;
    var silver = rem div 1000;
    var bronze = rem mod 1000;
    return { gold: gold, silver: silver, bronze: bronze };
}

/// currency_format_bronze(_bronze) → "Xg Ys Zb"
function currency_format_bronze(_bronze) {
    var bsg = currency_bronze_to_bsg(_bronze);
    return string(bsg.gold) + "g " + string(bsg.silver) + "s " + string(bsg.bronze) + "c";
}

/// inv_sell_amount(_item_key, _amount) → bool
/// Sells N items at the item’s bronze price (fast, single write).
function inv_sell_amount(_item_key, _amount) {
    var amt = clamp(floor(_amount), 1, inventory_count(_item_key));
    if (amt <= 0) return false;

    var price_per = inv_get_sell_price_bronze(_item_key);
    var total_b   = price_per * amt;

    if (!remove_from_inventory(_item_key, amt)) return false;
    currency_add_bronze(total_b);
    show_debug_message("💰 Sold " + string(amt) + "x " + string(_item_key) + " for " + currency_format_bronze(total_b));
    return true;
}
