/// oPortalTile: Step
can_enter = portal_requirement_met();

if (can_enter) {
    if (variable_global_exists("player") && instance_exists(global.player)) {
        var p  = global.player;
        var bb = portal_get_aabb(trigger_inflate);

        // Edge distance <= margin ⇒ close enough to portal edges
        var d = point_to_aabb_edge_distance(p.x, p.y, bb);

        // NOTE: fixed previous assignment bug; this uses proper boolean check
        if (d <= trigger_margin && !p.teleport_started && !global.auto_combat_enabled) {
            p.teleport_started = true;
            portal_activate(goto_portal_id);
        }
    }
}
