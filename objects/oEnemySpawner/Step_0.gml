// Wait until oGame.Room Start has built the grids & sizes
if (is_undefined(global.path_grid_width) || is_undefined(global.walkable_grid)) exit;

// --- 1) Clean up destroyed instances BEFORE checking the cap ---
for (var i = array_length(spawned_enemies) - 1; i >= 0; i--) {
    if (!instance_exists(spawned_enemies[i])) array_delete(spawned_enemies, i, 1);
}

// --- 2) Tick the spawn timer and only attempt on interval ---
spawn_timer++;
if (spawn_timer < spawn_interval) exit;
spawn_timer = 0; // we attempted a spawn this step (success or not)

// If we're already at cap after cleanup, do nothing this interval
if (array_length(spawned_enemies) >= spawn_limit) exit;

// --- 3) Try to find a valid spawn tile ---
var cell   = global.grid_cell_size;
var grid_w = global.path_grid_width;
var grid_h = global.path_grid_height;

var found = false;
var tile_x, tile_y;

repeat (20) {
    tile_x = irandom(grid_w - 1);
    tile_y = irandom(grid_h - 1);

    if (global.walkable_grid[# tile_x, tile_y] == 0 && !tile_in_exclusion_zone(tile_x, tile_y)) {
        found = true;
        break;
    }
}

if (found) {
    var spawn_x = tile_x * cell + cell * 0.5;
    var spawn_y = tile_y * cell + cell * 0.5;

    // Spawn generic enemy object (configurable)
    var e = instance_create_layer(spawn_x, spawn_y, "Instances", enemy_object);
    e.spawner = id; // mark owner spawner

    // 🔹 Fade-in initialization (applies to ALL enemies created by this spawner)
    with (e) {
        image_alpha         = 0;
        spawn_fading        = true;
        spawn_fade_timer    = 0;
        spawn_fade_duration = 24;   // 24 steps @60fps ≈ 0.4s (tweak per feel)
        targetable          = false; // not targetable until visible
    }

    array_push(spawned_enemies, e); // track only our own spawns
}
