/// @function progress_reset_all()
/// @desc Resets all skills to level 1 and xp 0, persists immediately.
function progress_reset_all() {
    if (!is_struct(global.progress)) global.progress = progress_defaults();

    // Ensure skills struct exists
    if (!variable_struct_exists(global.progress, "skills") || !is_struct(global.progress.skills)) {
        global.progress.skills = {};
    }

    // Reset every known skill
    var names = variable_struct_get_names(global.progress.skills);
    for (var i = 0; i < array_length(names); i++) {
        var k = names[i];
        var s = variable_struct_get(global.progress.skills, k);
        if (!is_struct(s)) s = {};
        s.level = 1;
        s.xp    = 0;
        variable_struct_set(global.progress.skills, k, s);
    }

    // Debounce + embed into main save (oGame owns disk writes)
    global.progress.autosave_cooldown = 1;

    if (!variable_struct_exists(global.save, "progress")) {
        variable_struct_set(global.save, "progress", global.progress);
    } else {
        global.save.progress = global.progress;
    }

    // Force a write NOW
    var now_dt = date_current_datetime();
    global.save.last_save_dt   = now_dt;
    global.save.last_active_dt = now_dt;
    global.save.portal_id      = global.current_portal;

    var json = json_stringify(global.save);
    var f = file_text_open_write("save.json");
    file_text_write_string(f, json);
    file_text_close(f);
}
