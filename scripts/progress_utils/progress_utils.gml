/// @function progress_get_level(skill)
/// @returns {real} level or 1 if missing
function progress_get_level(_skill) {
    var s = progress_get_skill(_skill);
    return is_struct(s) ? s.level : 1;
}

/// @function progress_get_xp_frac(skill)
/// @desc 0..1 progress within current level (safe even if uninitialized)
function progress_get_xp_frac(_skill) {
    var s = progress_get_skill(_skill);
    if (!is_struct(s)) return 0;
    var need = max(1, progress_xp_to_next(s.level));
    return clamp(s.xp / need, 0, 1);
}

/// @function progress_award_safe(skill, amount)
/// @desc Convenience: silently create skill and award XP.
function progress_award_safe(_skill, _amount) {
    return progress_award_xp(_skill, _amount);
}

/// @function progress_debug_add(skill, levels)
/// @desc Grant enough XP to gain N levels (useful for testing)
function progress_debug_add(_skill, _levels) {
    if (_levels <= 0) return 0;
    var gained = 0;
    for (var i = 0; i < _levels; i++) {
        var lvl = progress_get_level(_skill);
        gained += progress_award_xp(_skill, progress_xp_to_next(lvl));
    }
    return gained;
}
