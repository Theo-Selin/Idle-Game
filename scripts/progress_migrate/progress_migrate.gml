/// @function progress_migrate(data)
/// @desc Ensures required fields exist on loaded progress data.
///       Returns a valid migrated struct (never crashes on old saves).
function progress_migrate(_data) {
    // If the loaded thing isn't a struct, fallback to defaults
    if (!is_struct(_data)) return progress_defaults();

    var out = _data;

    // Core fields
    if (!variable_struct_exists(out, "version"))               out.version = 1;
    if (!variable_struct_exists(out, "autosave_cooldown"))     out.autosave_cooldown = 0;
    if (!variable_struct_exists(out, "autosave_cooldown_max")) out.autosave_cooldown_max = 15;

    // Skills struct
    if (!variable_struct_exists(out, "skills") || !is_struct(out.skills)) {
        out.skills = {};
    }

    // Ensure required skills exist and are valid
    var ensure_list = ["combat", "woodcutting"]; // add "mining" later
    var skills = out.skills;

    for (var i = 0; i < array_length(ensure_list); i++) {
        var key = ensure_list[i];

        if (!variable_struct_exists(skills, key) || !is_struct(variable_struct_get(skills, key))) {
            // Create fresh entry
            variable_struct_set(skills, key, { level: 1, xp: 0 });
        } else {
            // Fill missing fields on existing entry
            var s = variable_struct_get(skills, key);
            if (!variable_struct_exists(s, "level")) s.level = 1;
            if (!variable_struct_exists(s, "xp"))    s.xp    = 0;
        }
    }

    return out;
}
