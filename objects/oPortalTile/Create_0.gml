/// oPortalTile: Create Event
depth = 0;
solid = false;             // never block physics/movement
is_blocking = false;       // so your mp_grid / blocked checks ignore it

// --- Trigger settings (edge-based; replaces trigger_radius)
if (!variable_instance_exists(id, "trigger_margin"))  trigger_margin  = 12; // pixels from edges
if (!variable_instance_exists(id, "trigger_inflate")) trigger_inflate = 0;  // expands/shrinks the bounds
if (!variable_instance_exists(id, "use_glow_bounds_fallback")) use_glow_bounds_fallback = true;

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
            woodcutting: { level: 1, xp: 0 }
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

// --- Get portal bounds as an axis-aligned box (struct)
function portal_get_aabb(_inflate) {
    // Prefer collision bbox if sprite/mask present (auto-handles scale & origin)
    if (sprite_index != -1 || mask_index != -1) {
        var _l = bbox_left   - _inflate;
        var _t = bbox_top    - _inflate;
        var _r = bbox_right  + _inflate;
        var _b = bbox_bottom + _inflate;
        return { l: _l, t: _t, r: _r, b: _b };
    }

    // Fallback: approximate from glow settings if requested
    if (use_glow_bounds_fallback) {
        var _bw = 64; if (variable_instance_exists(id,"glow_beam_width"))  _bw = variable_instance_get(id,"glow_beam_width");
        var _bh = 64; if (variable_instance_exists(id,"glow_beam_height")) _bh = variable_instance_get(id,"glow_beam_height");

        // Glow centered at (x, y+16), arc extends upward
        var _cx = x;
        var _cy = y + 16;

        var _l2 = floor(_cx - (_bw * 0.5)) - _inflate;
        var _r2 = ceil (_cx + (_bw * 0.5)) + _inflate;
        var _t2 = floor(_cy - _bh)         - _inflate;
        var _b2 = ceil (_cy)               + _inflate;
        return { l: _l2, t: _t2, r: _r2, b: _b2 };
    }

    // Last resort: tiny box around instance position
    var _l3 = x - 4 - _inflate;
    var _r3 = x + 4 + _inflate;
    var _t3 = y - 4 - _inflate;
    var _b3 = y + 4 + _inflate;
    return { l: _l3, t: _t3, r: _r3, b: _b3 };
}

// --- Distance from point to AABB edges (0 when inside)
function point_to_aabb_edge_distance(_px, _py, _bb) {
    var _dx = 0;
    if (_px < _bb.l) _dx = _bb.l - _px; else if (_px > _bb.r) _dx = _px - _bb.r;

    var _dy = 0;
    if (_py < _bb.t) _dy = _bb.t - _py; else if (_py > _bb.b) _dy = _py - _bb.b;

    if (_dx == 0 && _dy == 0) return 0;
    if (_dx == 0) return _dy;
    if (_dy == 0) return _dx;
    return sqrt((_dx * _dx) + (_dy * _dy));
}
