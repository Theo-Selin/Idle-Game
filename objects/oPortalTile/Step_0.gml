/// oPortalTile: Step
can_enter = portal_requirement_met();

// Distance-based trigger so collisions never interfere
if (can_enter) {
    if (variable_global_exists("player") && instance_exists(global.player)) {
        var p = global.player;
        var r = trigger_radius; // per-instance overrideable
        if (point_distance(p.x, p.y, x, y) <= r) {
            if (!p.teleport_started && global.auto_combat_enabled = false) {
                p.teleport_started = true;
                portal_activate(goto_portal_id);
            }
        }
    }
}
