/// build_enemy_drops_index()
/// Creates global.enemy_drops: "oSlime" -> [{ item, chance, min, max }, ...]
function build_enemy_drops_index() {
    global.enemy_drops = {};

    var keys = variable_struct_get_names(global.item_data);
    for (var i = 0; i < array_length(keys); i++) {
        var item_id = keys[i];
        var meta    = variable_struct_get(global.item_data, item_id);

        // Defensive: require a struct
        if (!is_struct(meta)) continue;

        // Read drops only if present and an array (avoid "variable not set" error)
        if (!(variable_struct_exists(meta, "drops"))) continue;
        var drops_arr = variable_struct_get(meta, "drops");
        if (!is_array(drops_arr)) continue;

        for (var j = 0; j < array_length(drops_arr); j++) {
            var d = drops_arr[j];
            if (!is_struct(d)) continue;

            // Be forgiving: allow "change" as alias for "chance"
            var ch = 0;
            if (variable_struct_exists(d, "chance") && is_real(d.chance)) ch = d.chance;
            else if (variable_struct_exists(d, "change") && is_real(d.change)) ch = d.change;

            if (ch <= 0) continue;

            // Enemy name
            if (!variable_struct_exists(d, "enemy")) continue;
            var en = d.enemy;
            if (!is_string(en) || en == "") continue;

            // Amounts
            var mn = (variable_struct_exists(d, "min") && is_real(d.min)) ? d.min : 1;
            var mx = (variable_struct_exists(d, "max") && is_real(d.max)) ? d.max : mn;

            // Bucket for this enemy
            var bucket = variable_struct_get(global.enemy_drops, en);
            if (is_undefined(bucket)) bucket = [];

            array_push(bucket, { item: item_id, chance: ch, min: mn, max: mx });
            variable_struct_set(global.enemy_drops, en, bucket);
        }
    }

    show_debug_message("✅ build_enemy_drops_index: " + string(array_length(variable_struct_get_names(global.enemy_drops))) + " enemy keys");
}
