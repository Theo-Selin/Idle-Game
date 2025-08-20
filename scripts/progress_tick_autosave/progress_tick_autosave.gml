/// @function progress_tick_autosave()
/// @desc Safe debounce tick; works even if progress isn't initialized yet.
function progress_tick_autosave() {
    if (!variable_global_exists("progress") || !is_struct(global.progress)) {
        return; // nothing to do yet
    }

    var p = global.progress;

    if (!variable_struct_exists(p, "autosave_cooldown"))     p.autosave_cooldown = 0;
    if (!variable_struct_exists(p, "autosave_cooldown_max")) p.autosave_cooldown_max = 15;

    if (p.autosave_cooldown > 0) {
        p.autosave_cooldown -= 1;
        if (p.autosave_cooldown <= 0) {
            progress_save();
        }
    }
}
