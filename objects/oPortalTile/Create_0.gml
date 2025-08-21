/// oPortalTile: Create Event
depth = 0;
solid = false;             // never block physics/movement
is_blocking = false;       // so your mp_grid / blocked checks ignore it

// In oPortalTile Create
if (!variable_instance_exists(id, "trigger_radius")) trigger_radius = 32;

// Destination room (already in your code)
if (!variable_instance_exists(id, "goto_portal_id")) {
    goto_portal_id = ROOM_HOME_OUTSIDE;
}

// ---- Level requirement defaults (can be overridden per-instance via Creation Code)
if (!variable_instance_exists(id, "req_skill"))  req_skill  = "combat";
if (!variable_instance_exists(id, "req_level"))  req_level  = 1;

if (!variable_instance_exists(id, "lock_sprite"))      lock_sprite      = noone; // optional sprite
if (!variable_instance_exists(id, "lock_offset_y"))    lock_offset_y    = -24;
if (!variable_instance_exists(id, "lock_offset_x"))    lock_offset_x    = -24;
if (!variable_instance_exists(id, "lock_text_color"))  lock_text_color  = c_red;

// Cached computed flag (updated in Step)
can_enter = true; // will be recomputed in Step

// Safe fallback if global.progress is missing
if (!variable_global_exists("progress") || !is_struct(global.progress)) {
    global.progress = {
        skills: {
            combat  : { level: 1, xp: 0 },
            chopping: { level: 1, xp: 0 }
        }
    };
}

// --- Internal helper to check requirement
function portal_requirement_met() {
    var _p = global.progress;
    if (!is_struct(_p)) return false;

    // Get skills struct
    var _skills = variable_struct_get(_p, "skills");
    if (!is_struct(_skills)) return false;

    // Ensure requested skill exists
    if (!variable_struct_exists(_skills, req_skill)) return false;

    var _skill_struct = variable_struct_get(_skills, req_skill);
    if (!is_struct(_skill_struct)) return false;

    // Read "level" safely
    var _lvl = 1;
    if (variable_struct_exists(_skill_struct, "level")) {
        _lvl = variable_struct_get(_skill_struct, "level");
    }
    return (_lvl >= req_level);
}
