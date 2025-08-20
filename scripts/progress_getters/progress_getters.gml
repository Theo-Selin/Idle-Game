/// @function progress_skill_exists(skill_name)
function progress_skill_exists(_skill) {
    return variable_global_exists("progress")
        && is_struct(global.progress)
        && variable_struct_exists(global.progress, "skills")
        && is_struct(global.progress.skills)
        && variable_struct_exists(global.progress.skills, _skill);
}


/// @function progress_get_skill(skill_name)
/// @desc Returns the skill struct (level,xp) or undefined.
function progress_get_skill(_skill) {
    if (!progress_skill_exists(_skill)) return undefined;
    return variable_struct_get(global.progress.skills, _skill);
}

