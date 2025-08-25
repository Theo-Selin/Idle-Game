/// @function progress_reset_all()
/// @desc Resets all skills to level 1 / xp 0 AND all upgrades to level 0, then persists immediately.
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

    // --- Reset all upgrades (level -> 0) ---
    if (!variable_global_exists("upgrades") || !is_struct(global.upgrades)) {
        global.upgrades = {};
    }

    // Prefer defs to know which keys exist; fallback to whatever's in global.upgrades
    if (variable_global_exists("upgrade_defs") && is_struct(global.upgrade_defs)) {
        var ukeys = variable_struct_get_names(global.upgrade_defs);
        for (var ui = 0; ui < array_length(ukeys); ui++) {
            var key = ukeys[ui];
            var st  = variable_struct_get(global.upgrades, key);
            if (!is_struct(st)) st = {};
            st.level = 0; // reset
            variable_struct_set(global.upgrades, key, st);
        }
    } else {
        // No defs available; reset any existing upgrade entries that have a level
        var unames = variable_struct_get_names(global.upgrades);
        for (var uj = 0; uj < array_length(unames); uj++) {
            var k2 = unames[uj];
            var st2 = variable_struct_get(global.upgrades, k2);
            if (!is_struct(st2)) st2 = {};
            st2.level = 0;
            variable_struct_set(global.upgrades, k2, st2);
        }
    }

    // Debounce + embed into main save (oGame owns disk writes)
    global.progress.autosave_cooldown = 1;

    if (!variable_struct_exists(global, "save") || !is_struct(global.save)) global.save = {};

    // Persist progress
    if (!variable_struct_exists(global.save, "progress")) {
        variable_struct_set(global.save, "progress", global.progress);
    } else {
        global.save.progress = global.progress;
    }

    // Persist upgrades
    if (!variable_struct_exists(global.save, "upgrades")) {
        variable_struct_set(global.save, "upgrades", global.upgrades);
    } else {
        global.save.upgrades = global.upgrades;
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

    // Immediately rebuild live stats so UI/game reflect the reset
    var p = noone;
    if (variable_global_exists("player") && instance_exists(global.player)) p = global.player;
    else if (instance_number(oPlayer) > 0) p = instance_find(oPlayer, 0);
    if (p != noone) recalc_stats(p);
}
