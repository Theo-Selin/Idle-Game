/// drop_loot(x, y, type, amount, source, offset_x, offset_y)
function drop_loot(_x, _y, _type, _amount, _source_instance, _offset_x = 0, _offset_y = -32) {
    // Launch position (visually above source object)
    var start_x = _x + _offset_x;
    var start_y = _y + _offset_y;

    // Create loot instance
    var loot = instance_create_layer(start_x, start_y, "Instances", oLoot);
    loot.loot_type = _type;
    loot.loot_amount = _amount;

    // Store launch position for arc animation
    loot.drop_start_x = start_x;
    loot.drop_start_y = start_y;

    // Search for valid drop location
    var tries = 20;

    for (var i = 0; i < tries; i++) {
        var offset_x = random_range(-16, 16); // random horizontal spread
        var offset_y = random_range(20, 36);  // always downward in Y

        var tx = _source_instance.x + offset_x;
        var ty = _source_instance.y + offset_y;

        // Convert to grid cell
        var cell_x = floor(tx / global.grid_cell_size);
        var cell_y = floor(ty / global.grid_cell_size);

        // Only drop on walkable tiles
        if (variable_global_exists("path_grid") && !mp_grid_get_cell(global.path_grid, cell_x, cell_y)) {
            loot.drop_target_x = tx;
            loot.drop_target_y = ty;
            break;
        }
    }

    // Arc animation config
    loot.drop_duration = 30;   // animation frames
    loot.is_dropping = true;
    loot.scale = 0.5;          // start small for launch effect

    // Set sprite based on loot type
    switch (_type) {
        case "oak_log": loot.sprite_index = spr_oak_log; break;
		case "mushroom": loot.sprite_index = spr_mushroom; break;
		case "coin_copper": loot.sprite_index = spr_coin_copper; break;
		case "cloth": loot.sprite_index = spr_cloth; break;
        // Add other resource types here
    }

    show_debug_message("📦 Dropped loot: " + _type + " x" + string(_amount));
}
