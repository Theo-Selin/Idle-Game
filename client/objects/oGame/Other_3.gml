/// oGame.Game End
// Final embed of progress into the main save and write once
if (is_struct(global.progress)) {
    if (!variable_struct_exists(global.save, "progress")) {
        variable_struct_set(global.save, "progress", global.progress);
    } else {
        global.save.progress = global.progress;
    }
}

var now_dt = date_current_datetime();
global.save.last_save_dt   = now_dt;
global.save.last_active_dt = now_dt;
global.save.portal_id      = global.current_portal;

// Write one combined file
var json = json_stringify(global.save);
var f = file_text_open_write("save.json");
file_text_write_string(f, json);
file_text_close(f);


// Cleanup room-local handles
if (!is_undefined(global.path_grid))     mp_grid_destroy(global.path_grid);
if (!is_undefined(global.walkable_grid)) ds_grid_destroy(global.walkable_grid);
