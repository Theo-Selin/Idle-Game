/// @function progress_award_xp(skill_name, amount)
/// @returns {real} levels_gained
function progress_award_xp(_skill, _amount) {
    if (_amount <= 0) return 0;

    // Ensure progress exists (loads from disk if needed)
    if (!variable_global_exists("progress") || !is_struct(global.progress)) {
        if (function_exists(progress_init)) progress_init(); else global.progress = progress_defaults();
    }

    // Ensure skills struct exists
    if (!variable_struct_exists(global.progress, "skills") || !is_struct(global.progress.skills)) {
        global.progress.skills = {};
    }

    // Ensure the skill entry exists
    if (!variable_struct_exists(global.progress.skills, _skill)) {
        variable_struct_set(global.progress.skills, _skill, { level: 1, xp: 0 });
    }

    var s = variable_struct_get(global.progress.skills, _skill);
    s.xp += floor(_amount);

    var levels_gained = 0;
    while (s.xp >= progress_xp_to_next(s.level)) {
        s.xp -= progress_xp_to_next(s.level);
        s.level += 1;
        levels_gained += 1;
        progress_on_level_up(_skill, s.level);
    }

    if (!variable_struct_exists(global.progress, "autosave_cooldown_max")) global.progress.autosave_cooldown_max = 15;
    global.progress.autosave_cooldown = global.progress.autosave_cooldown_max;

    return levels_gained;
}
