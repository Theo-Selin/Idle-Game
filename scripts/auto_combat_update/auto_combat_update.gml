/// auto_combat_update(player)
/// - Retargets only when needed
/// - Rate-limited to reduce pathing spam
function auto_combat_update(player) {
    with (player) {
        if (!global.auto_combat_enabled) exit;

        // Safety init
        if (is_undefined(auto_scan_cooldown)) auto_scan_cooldown = 0;
        if (is_undefined(auto_scan_interval)) auto_scan_interval = 12; // ~0.2s at 60fps

        // Cooldown tick
        if (auto_scan_cooldown > 0) { auto_scan_cooldown--; exit; }

        // If we already have a valid combat target, do nothing
        var has_valid_target = false;
        if (target != noone && instance_exists(target)) {
            var alive_ok = !variable_instance_exists(target, "hp") || (target.hp > 0);
            has_valid_target = alive_ok && (action_type == "combat" || state == "moving_to_combat" || state == "combat");
        }

        if (has_valid_target) {
            auto_scan_cooldown = auto_scan_interval; // check again later
            exit;
        }

        // Otherwise, find closest enemy and engage
        var enemy = find_closest_enemy(x, y);

        if (enemy != noone) {
            // Respect your unified targeting system
            set_target_action(id, enemy, "combat");
            // Small delay to avoid instant re-scan if path fails (your set_target_action gracefully resets)
            auto_scan_cooldown = auto_scan_interval;
        } else {
            // No enemies right now; scan a bit less frequently
            auto_scan_cooldown = auto_scan_interval * 2;
        }
    }
}
