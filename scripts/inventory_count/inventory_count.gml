/// inventory_count(_type_key) → amount
/// Currency-aware read (no 'id' parameter)
function inventory_count(_type_key) {
    var key = string(_type_key);

    // Currency via pools
    if (key == "coin_copper" || key == "coin_bronze") {
        return currency_total_bronze();
    } else if (key == "coin_silver") {
        return currency_total_bronze() div 1000;
    } else if (key == "coin_gold") {
        return currency_total_bronze() div 1000000;
    }

    var amt = variable_struct_get(global.save.inventory, key);
    return is_undefined(amt) ? 0 : amt;
}
