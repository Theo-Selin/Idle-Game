/// oGame.Room End
// Keep embedded progress fresh at room transitions (no file I/O here)
if (is_struct(global.progress)) {
    if (!variable_struct_exists(global.save, "progress")) {
        variable_struct_set(global.save, "progress", global.progress);
    } else {
        global.save.progress = global.progress;
    }
    // Optionally mark dirty to encourage an earlier autosave after room change
    global.__save_dirty = true;
}


if (!is_undefined(global.path_grid)) {
    mp_grid_destroy(global.path_grid);
    global.path_grid = undefined;
}
if (!is_undefined(global.walkable_grid)) {
    ds_grid_destroy(global.walkable_grid);
    global.walkable_grid = undefined;
}
