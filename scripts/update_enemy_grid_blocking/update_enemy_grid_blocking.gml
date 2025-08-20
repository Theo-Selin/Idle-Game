/// @function scr_update_enemy_grid_blocking(inst)
/// @desc Dynamically updates enemy blocking in pathfinding and walkable grids
/// @param inst The enemy instance to update

function update_enemy_grid_blocking(inst) {
    var cell = global.grid_cell_size;

    // Current grid position based on enemy's world coordinates
    var gx = inst.x div cell;
    var gy = inst.y div cell;

    // Exit early if tile is invalid or in exclusion zone
    if (!tile_within_bounds(gx, gy)) return;
    if (tile_in_exclusion_zone(gx, gy)) return;

    // Only update if the grid position changed
    if (gx != inst.grid_x || gy != inst.grid_y) {
        // Clear the previously occupied tile, if valid
        if (tile_within_bounds(inst.grid_x, inst.grid_y) &&
            !tile_in_exclusion_zone(inst.grid_x, inst.grid_y)) {
            
            mp_grid_clear_cell(global.path_grid, inst.grid_x, inst.grid_y);
            global.walkable_grid[# inst.grid_x, inst.grid_y] = 0;
        }

        // Mark the new tile as blocked, only if not already
        if (!tile_is_blocked(gx, gy)) {
            mp_grid_add_cell(global.path_grid, gx, gy);
            global.walkable_grid[# gx, gy] = 1;
        }

        // Store the new tile position
        inst.grid_x = gx;
        inst.grid_y = gy;
    }
}
