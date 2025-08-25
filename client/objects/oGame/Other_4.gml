/// oGame.Room Start (patched)
if (instance_exists(oFadeController)) {
    oFadeController.fade = 1;
    oFadeController.fading_out = false;
    oFadeController.on_fade_complete = undefined;
}

// 🔹 NEW: allow a couple frames of post-spawn sync (optional but helps)
__sync_frames = 3;

// 🔹 NEW: sync WeatherDirector immediately to the last known global ToD
// (If you placed oWeatherDirector in this room, it will start at the correct time.)
var __wd = object_exists(oWeatherDirector) ? instance_find(oWeatherDirector, 0) : noone;
if (instance_exists(__wd)) {
    __wd.set_time_of_day(variable_global_exists("time_of_day") ? clamp(global.time_of_day, 0, 1) : 1.0);
}

// 🔹 NEW: reset the cached FX layer id for this room (layer ids are room-local)
global.fx_follow_layer_id = -1;

// Safety: tear down leftovers if any (now using Undefined sentinel)
if (!is_undefined(global.path_grid)) {
    mp_grid_destroy(global.path_grid);
    global.path_grid = undefined;
}
if (!is_undefined(global.walkable_grid)) {
    ds_grid_destroy(global.walkable_grid);
    global.walkable_grid = undefined;
}

// Build grids for this room
global.grid_cell_size = 32;
var cell   = global.grid_cell_size;
var grid_w = room_width  div cell;
var grid_h = room_height div cell;

// After: grid_w, grid_h computed
global.path_grid_width  = grid_w;
global.path_grid_height = grid_h;

// Exclusion zone is per-room, so compute it here too
global.exclusion_width_tiles  = 40;
global.exclusion_height_tiles = 22;

var cx = grid_w div 2;
var cy = grid_h div 2;

global.exclusion_min_x = cx - (global.exclusion_width_tiles div 2);
global.exclusion_max_x = cx + (global.exclusion_width_tiles div 2) - 1;
global.exclusion_min_y = cy - (global.exclusion_height_tiles div 2);
global.exclusion_max_y = cy + (global.exclusion_height_tiles div 2) - 1;

global.path_grid_width  = grid_w;
global.path_grid_height = grid_h;

global.path_grid     = mp_grid_create(0, 0, grid_w, grid_h, cell, cell);
global.walkable_grid = ds_grid_create(grid_w, grid_h);
ds_grid_clear(global.walkable_grid, 0);

// Mark blocked cells from tile layer (guard if layer missing)
if (layer_exists("CollisionTiles")) {
    var tilemap_id = layer_tilemap_get_id("CollisionTiles");
    for (var xx = 0; xx < room_width; xx += cell) {
        for (var yy = 0; yy < room_height; yy += cell) {
            if (tilemap_get_at_pixel(tilemap_id, xx, yy) != 0) {
                var gx = xx div cell, gy = yy div cell;
                mp_grid_add_cell(global.path_grid, gx, gy);
                global.walkable_grid[# gx, gy] = 1;
            }
        }
    }
}

mp_grid_add_instances(global.path_grid, oSolid, false);
mp_grid_add_instances(global.path_grid, oEnemy, false);

handle_portal_audio(global.current_portal);
global.previous_portal = global.current_portal;

// 🔹 NEW: if it's already night when entering this room, spawn the follower flame now
// (so you don't have to wait for the Step hysteresis to kick in)
if (variable_global_exists("is_night") && global.is_night && instance_exists(oPlayer) && !instance_exists(global.fx_follow_flame)) {
    // Resolve or create an FX layer id for THIS room (no renaming)
    if (layer_exists(global.fx_follow_layer)) {
        global.fx_follow_layer_id = layer_get_id(global.fx_follow_layer);
    } else {
        global.fx_follow_layer_id = layer_create(-100000); // very front
    }

    var __ply = instance_find(oPlayer, 0);
    global.fx_follow_flame = instance_create_layer(__ply.x, __ply.y, global.fx_follow_layer_id, oFollowerFlame);
}
